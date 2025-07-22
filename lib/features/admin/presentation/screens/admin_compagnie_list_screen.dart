import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/company_structure_service.dart';
import '../../../../services/admin_compagnie_crud_service.dart';
import '../../../../services/company_management_service.dart';
import '../../../../services/database_cleanup_service.dart';
import '../../../../services/password_reset_service.dart';
import '../../../../services/company_admin_sync_service.dart';
import '../../../../services/admin_duplicate_fix_service.dart';
import 'admin_compagnie_details_screen.dart';
import 'password_reset_dialog.dart';

/// 📋 Écran de liste des Admins Compagnie avec design moderne
class AdminCompagnieListScreen extends StatefulWidget {
  const AdminCompagnieListScreen({Key? key}) : super(key: key);

  @override
  State<AdminCompagnieListScreen> createState() => _AdminCompagnieListScreenState();
}

class _AdminCompagnieListScreenState extends State<AdminCompagnieListScreen> {
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _admins = [];
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _adminStatistics = {};
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('[ADMIN_COMPAGNIE_LIST] 🔄 Début rechargement des données');

      // Charger les données des compagnies
      final report = await CompanyStructureService.getCompanyReport();

      // Charger les données des admins
      final admins = await AdminCompagnieCrudService.getAllAdminCompagnie();
      final adminStats = await AdminCompagnieCrudService.getStatistics();

      debugPrint('[ADMIN_COMPAGNIE_LIST] 📊 Données chargées: ${admins.length} admins');

      // Debug: Afficher le statut de chaque admin
      for (final admin in admins) {
        debugPrint('[ADMIN_COMPAGNIE_LIST] 👤 Admin ${admin['displayName']}: isActive=${admin['isActive']}, status=${admin['status']}, compagnieId=${admin['compagnieId']}');
      }

      // Vérification automatique des doublons
      _checkForDuplicatesInBackground();

      if (mounted) {
        setState(() {
          _companies = List<Map<String, dynamic>>.from(report['companies']);
          _statistics = report['statistics'];
          _admins = admins;
          _adminStatistics = adminStats;
          _isLoading = false;
        });
        debugPrint('[ADMIN_COMPAGNIE_LIST] ✅ Interface mise à jour');
      }
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_LIST] ❌ Erreur chargement: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'Gestion Admins Compagnie',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Options avancées',
              onSelected: (value) {
                switch (value) {
                  case 'diagnose':
                    _diagnoseCompanies();
                    break;
                  case 'duplicates':
                    _detectDuplicates();
                    break;
                  case 'search':
                    _searchCompaniesInAllCollections();
                    break;
                  case 'recreate':
                    _recreateCompaniesCollection();
                    break;
                  case 'create_default':
                    _createDefaultCompanies();
                    break;
                  case 'clear_all':
                    _clearAllCompanies();
                    break;
                  case 'full_cleanup':
                    _fullDatabaseCleanup();
                    break;
                  case 'quick_clean':
                    _quickCleanup();
                    break;
                  case 'unify_now':
                    _unifyNow();
                    break;
                  case 'delete_all':
                    _deleteAllDefinitively();
                    break;
                  case 'delete_auto':
                    _deleteAutoCreatedData();
                    break;
                  case 'fix_links':
                    _fixExistingLinks();
                    break;
                  case 'refresh':
                    _forceRefresh();
                    break;
                  case 'fix_duplicates':
                    _diagnoseDuplicateAdmins();
                    break;
                  case 'test_sync':
                    _testCompanyAdminSync();
                    break;

                  case 'diagnose':
                    _diagnoseCollections();
                    break;
                  case 'fix':
                    _fixExistingLinks();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'diagnose',
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: Color(0xFF059669)),
                      SizedBox(width: 12),
                      Text('Diagnostiquer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicates',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Détecter doublons'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded, color: Colors.purple),
                      SizedBox(width: 12),
                      Text('Chercher collections'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'recreate',
                  child: Row(
                    children: [
                      Icon(Icons.add_business_rounded, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Recréer collection'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'create_default',
                  child: Row(
                    children: [
                      Icon(Icons.factory_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Créer compagnies',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Vider collection',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'full_cleanup',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'NETTOYAGE COMPLET',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'quick_clean',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Nettoyage rapide',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'unify_now',
                  child: Row(
                    children: [
                      Icon(Icons.merge_rounded, color: Colors.blue),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'UNIFIER MAINTENANT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SUPPRIMER TOUT',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_auto',
                  child: Row(
                    children: [
                      Icon(Icons.auto_delete_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Supprimer données auto',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'fix_links',
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Corriger liaisons',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value: 'diagnose',
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: Colors.purple),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Diagnostic DB',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'fix',
                  child: Row(
                    children: [
                      Icon(Icons.build_rounded, color: Colors.blue),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Corriger liaisons',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'fix_duplicates',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Corriger doublons admins',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'test_sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.blue),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Tester synchronisation',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _diagnoseDuplicateAdmins,
              icon: const Icon(Icons.content_copy_rounded),
              tooltip: 'Corriger doublons admins',
            ),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualiser',
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.business_rounded),
                text: 'Compagnies',
              ),
              Tab(
                icon: Icon(Icons.admin_panel_settings_rounded),
                text: 'Admins',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                ),
              )
            : TabBarView(
                children: [
                  // Onglet Compagnies
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatisticsCard(),
                        const SizedBox(height: 20),
                        _buildCompaniesWithAdminList(),
                        const SizedBox(height: 20),
                        _buildCompaniesWithoutAdminList(),
                      ],
                    ),
                  ),
                  // Onglet Admins avec CRUD
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAdminStatisticsCard(),
                        const SizedBox(height: 20),
                        _buildAdminsList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 📊 Carte des statistiques
  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Statistiques Globales',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Compagnies',
                  '${_statistics['totalCompanies'] ?? 0}',
                  Icons.business_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Avec Admin',
                  '${_statistics['companiesWithAdmin'] ?? 0}',
                  Icons.admin_panel_settings_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Sans Admin',
                  '${_statistics['companiesWithoutAdmin'] ?? 0}',
                  Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Couverture',
                  '${_statistics['adminCoverage'] ?? 0}%',
                  Icons.pie_chart_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🏢 Liste des compagnies avec admin
  Widget _buildCompaniesWithAdminList() {
    final companiesWithAdmin = _companies.where((c) => c['hasAdmin'] == true).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compagnies avec Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${companiesWithAdmin.length} compagnie(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (companiesWithAdmin.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucune compagnie avec admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...companiesWithAdmin.map((company) => _buildCompanyWithAdminCard(company)),
        ],
      ),
    );
  }

  Widget _buildCompanyWithAdminCard(Map<String, dynamic> company) {
    // Debug: Afficher le statut de la compagnie
    debugPrint('[COMPANY_CARD] Compagnie: ${company['nom']}, Status: ${company['status']}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: company['type'] == 'Takaful'
                        ? [Colors.purple, Colors.purple.shade700]
                        : [Colors.blue, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
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
                      company['nom'] ?? 'Nom non défini',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (company['code'] != null)
                      Text(
                        'Code: ${company['code']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: company['type'] == 'Takaful'
                      ? Colors.purple.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  company['type'] ?? 'Classique',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: company['type'] == 'Takaful'
                        ? Colors.purple.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_rounded, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Administrateur assigné',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  company['adminCompagnieNom'] ?? 'Nom non défini',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        company['adminCompagnieEmail'] ?? 'Email non défini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        final email = company['adminCompagnieEmail'];
                        if (email != null) {
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('📧 Email copié!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copier l\'email',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Boutons d'action pour la compagnie
          Row(
            children: [
              // Statut de la compagnie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isCompanyActive(company)
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCompanyActive(company)
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 16,
                      color: _isCompanyActive(company)
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isCompanyActive(company)
                          ? 'Active'
                          : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isCompanyActive(company)
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bouton pour activer/désactiver
              ElevatedButton.icon(
                onPressed: () => _toggleCompanyStatus(company),
                icon: Icon(
                  _isCompanyActive(company)
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  size: 16,
                ),
                label: Text(
                  _isCompanyActive(company)
                      ? 'Désactiver'
                      : 'Activer',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompanyActive(company)
                      ? Colors.orange
                      : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⚠️ Liste des compagnies sans admin
  Widget _buildCompaniesWithoutAdminList() {
    final companiesWithoutAdmin = _companies.where((c) => c['hasAdmin'] != true).toList();
    
    if (companiesWithoutAdmin.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compagnies sans Admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${companiesWithoutAdmin.length} compagnie(s) nécessitent un admin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...companiesWithoutAdmin.map((company) => _buildCompanyWithoutAdminCard(company)),
        ],
      ),
    );
  }

  Widget _buildCompanyWithoutAdminCard(Map<String, dynamic> company) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: company['type'] == 'Takaful'
                    ? [Colors.purple, Colors.purple.shade700]
                    : [Colors.blue, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_rounded,
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
                  company['nom'] ?? 'Nom non défini',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (company['code'] != null)
                  Text(
                    'Code: ${company['code']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SANS ADMIN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showAssignAdminDialog(company),
                icon: const Icon(Icons.person_add_rounded, size: 14),
                label: const Text(
                  'Assigner',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Carte des statistiques des admins
  Widget _buildAdminStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Statistiques Admins',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Admins',
                  '${_adminStatistics['totalAdmins'] ?? 0}',
                  Icons.people_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Actifs',
                  '${_adminStatistics['activeAdmins'] ?? 0}',
                  Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Inactifs',
                  '${_adminStatistics['inactiveAdmins'] ?? 0}',
                  Icons.block_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Taux Connexion',
                  '${_adminStatistics['loginRate'] ?? 0}%',
                  Icons.login_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 👥 Liste des admins avec actions CRUD
  Widget _buildAdminsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liste des Admins Compagnie',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_admins.length} admin(s) • Actions CRUD disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_admins.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Aucun admin compagnie trouvé',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_admins.asMap().entries.map((entry) {
              final index = entry.key;
              final admin = entry.value;
              return _buildAdminCard(admin, index);
            })),
        ],
      ),
    );
  }

  /// 👤 Carte d'un admin avec actions CRUD
  Widget _buildAdminCard(Map<String, dynamic> admin, int index) {
    final isActive = admin['isActive'] == true;
    final companyData = admin['companyData'] as Map<String, dynamic>?;

    return Container(
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.green.shade50, Colors.white]
              : [Colors.red.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar avec statut
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [Colors.green, Colors.green.shade700]
                              : [Colors.red, Colors.red.shade700],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          isActive ? Icons.check_rounded : Icons.close_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              admin['displayName'] ?? '${admin['prenom']} ${admin['nom']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'ACTIF' : 'INACTIF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin['email'] ?? 'Email non défini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Afficher la raison de la désactivation si applicable
                      if (!isActive && admin['syncReason'] != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_rounded, size: 12, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  admin['syncReason'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (companyData != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business_rounded,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                companyData['nom'] ?? 'Compagnie non définie',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions CRUD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Bouton Voir Détails
                SizedBox(
                  width: 85,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToAdminDetails(admin),
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text(
                      'Détails',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                // Bouton Activer/Désactiver
                SizedBox(
                  width: 95,
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAdminStatus(admin),
                    icon: Icon(
                      isActive ? Icons.block_rounded : Icons.check_circle_rounded,
                      size: 14,
                    ),
                    label: Text(
                      isActive ? 'Désactiver' : 'Activer',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                // Bouton Réinitialiser mot de passe
                SizedBox(
                  width: 105,
                  child: ElevatedButton.icon(
                    onPressed: () => _resetAdminPassword(admin),
                    icon: const Icon(Icons.lock_reset_rounded, size: 14),
                    label: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                // Bouton Désactiver pour réassignation
                SizedBox(
                  width: 105,
                  child: ElevatedButton.icon(
                    onPressed: () => _deactivateAdminForReassignment(admin),
                    icon: const Icon(Icons.person_off_rounded, size: 14),
                    label: const Text(
                      'Réassigner',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                // Bouton Supprimer
                SizedBox(
                  width: 95,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeleteAdmin(admin),
                    icon: const Icon(Icons.delete_rounded, size: 14),
                    label: const Text(
                      'Supprimer',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔧 Diagnostiquer et corriger les doublons d'admins
  Future<void> _diagnoseDuplicateAdmins() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Diagnostic en cours...'),
          ],
        ),
      ),
    );

    try {
      final diagnosis = await AdminDuplicateFixService.diagnoseMultipleAdmins();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (!diagnosis['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur diagnostic: ${diagnosis['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final duplicateCompanies = diagnosis['duplicateCompanies'] as List<Map<String, dynamic>>;

      if (duplicateCompanies.isEmpty) {
        // Aucun doublon trouvé
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: _buildDialogTitle(
              icon: Icons.check_circle_rounded,
              text: 'Diagnostic terminé',
              iconColor: Colors.green,
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  '✅ Aucun doublon trouvé !',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Toutes les compagnies ont un seul admin actif.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Afficher les doublons trouvés et proposer la correction
      _showDuplicateAdminsDialog(diagnosis);
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📋 Afficher le dialogue des doublons d'admins
  void _showDuplicateAdminsDialog(Map<String, dynamic> diagnosis) {
    final duplicateCompanies = diagnosis['duplicateCompanies'] as List<Map<String, dynamic>>;
    final totalDuplicates = diagnosis['totalDuplicatesToFix'] as int;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: Icons.warning_amber_rounded,
          text: 'Doublons d\'admins détectés',
          iconColor: Colors.orange,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ${duplicateCompanies.length} compagnies ont plusieurs admins actifs',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    Text('📊 Total admins en doublon: $totalDuplicates'),
                    Text('🔧 Action: Garder le plus récent, désactiver les autres'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Compagnies concernées:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: duplicateCompanies.length,
                  itemBuilder: (context, index) {
                    final company = duplicateCompanies[index];
                    final admins = company['admins'] as List<Map<String, dynamic>>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🏢 ${company['compagnieNom']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('👥 ${admins.length} admins actifs:'),
                            ...admins.map((admin) => Padding(
                              padding: const EdgeInsets.only(left: 16, top: 4),
                              child: Text('• ${admin['displayName']} (${admin['email']})'),
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _fixDuplicateAdmins(false); // Simulation d'abord
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Simuler correction'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmFixDuplicateAdmins();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Corriger maintenant'),
          ),
        ],
      ),
    );
  }

  /// 🔍 Vérifier les doublons en arrière-plan
  Future<void> _checkForDuplicatesInBackground() async {
    try {
      final diagnosis = await AdminDuplicateFixService.diagnoseMultipleAdmins();

      if (diagnosis['success'] && diagnosis['duplicateCompanies'].isNotEmpty) {
        final duplicateCount = diagnosis['duplicateCompanies'].length;
        debugPrint('[ADMIN_COMPAGNIE_LIST] ⚠️ $duplicateCount compagnies avec doublons détectées');

        // Afficher une notification discrète
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('⚠️ $duplicateCount compagnies ont plusieurs admins actifs'),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      _diagnoseDuplicateAdmins();
                    },
                    child: const Text('CORRIGER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'X',
                textColor: Colors.white,
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[ADMIN_COMPAGNIE_LIST] ❌ Erreur vérification doublons: $e');
    }
  }

  /// 🧪 Tester la synchronisation compagnie-admin
  Future<void> _testCompanyAdminSync() async {
    // Sélectionner une compagnie pour tester
    final companiesWithAdmin = _companies.where((c) => c['hasAdmin'] == true).toList();

    if (companiesWithAdmin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune compagnie avec admin trouvée pour tester'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedCompany = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: Icons.science_rounded,
          text: 'Test synchronisation',
          iconColor: Colors.blue,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sélectionnez une compagnie pour tester la synchronisation:'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: companiesWithAdmin.length,
                  itemBuilder: (context, index) {
                    final company = companiesWithAdmin[index];
                    return ListTile(
                      leading: Icon(
                        Icons.business_rounded,
                        color: _isCompanyActive(company) ? Colors.green : Colors.red,
                      ),
                      title: Text(company['nom'] ?? 'Sans nom'),
                      subtitle: Text('Admin: ${company['adminCompagnieNom'] ?? 'Aucun'}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isCompanyActive(company) ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isCompanyActive(company) ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isCompanyActive(company) ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(company),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedCompany != null) {
      _performSyncTest(selectedCompany);
    }
  }

  /// 🔬 Effectuer le test de synchronisation
  Future<void> _performSyncTest(Map<String, dynamic> company) async {
    final currentStatus = _isCompanyActive(company);
    final testStatus = !currentStatus; // Inverser pour tester

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Test de synchronisation en cours...'),
            const SizedBox(height: 8),
            Text('${testStatus ? 'Activation' : 'Désactivation'} de ${company['nom']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      debugPrint('[SYNC_TEST] 🧪 Test synchronisation: ${company['nom']} (${currentStatus} → $testStatus)');

      // Effectuer le test de synchronisation
      final result = await CompanyManagementService.toggleCompanyStatusWithSync(
        compagnieId: company['id'],
        newStatus: testStatus,
      );

      // Attendre un peu pour la synchronisation
      await Future.delayed(const Duration(seconds: 2));

      // Remettre le statut original
      final restoreResult = await CompanyManagementService.toggleCompanyStatusWithSync(
        compagnieId: company['id'],
        newStatus: currentStatus,
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Afficher le résultat
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: _buildDialogTitle(
            icon: result['success'] && restoreResult['success'] ? Icons.check_circle_rounded : Icons.error_rounded,
            text: 'Résultat du test',
            iconColor: result['success'] && restoreResult['success'] ? Colors.green : Colors.red,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🏢 Compagnie: ${company['nom']}'),
              const SizedBox(height: 8),
              Text('📊 Test effectué: ${currentStatus ? 'Actif' : 'Inactif'} → ${testStatus ? 'Actif' : 'Inactif'} → ${currentStatus ? 'Actif' : 'Inactif'}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (result['success'] && restoreResult['success'] ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (result['success'] && restoreResult['success'] ? Colors.green : Colors.red).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['success'] && restoreResult['success'] ? '✅ Test réussi' : '❌ Test échoué',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: result['success'] && restoreResult['success'] ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('1️⃣ Changement: ${result['success'] ? 'Réussi' : 'Échoué'}'),
                    if (result['success'])
                      Text('   Admins synchronisés: ${result['adminsUpdated'] ?? 0}'),
                    Text('2️⃣ Restauration: ${restoreResult['success'] ? 'Réussie' : 'Échouée'}'),
                    if (restoreResult['success'])
                      Text('   Admins synchronisés: ${restoreResult['adminsUpdated'] ?? 0}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadData(); // Recharger les données
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: result['success'] && restoreResult['success'] ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔄 Forcer le rechargement des données
  Future<void> _forceRefresh() async {
    debugPrint('[ADMIN_COMPAGNIE_LIST] 🔄 Rechargement forcé demandé');
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données actualisées'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// ⚠️ Confirmer la correction des doublons
  Future<void> _confirmFixDuplicateAdmins() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: Icons.warning_rounded,
          text: 'Confirmation correction',
          iconColor: Colors.red,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚠️ ATTENTION: Cette action va désactiver définitivement les admins en doublon.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 16),
            Text('🔧 Action qui sera effectuée:'),
            SizedBox(height: 8),
            Text('• Garder l\'admin le plus récent pour chaque compagnie'),
            Text('• Désactiver tous les autres admins de la même compagnie'),
            Text('• Mettre à jour les liaisons compagnie-admin'),
            SizedBox(height: 16),
            Text(
              '💡 Conseil: Faites d\'abord une simulation pour voir les changements.',
              style: TextStyle(color: Colors.blue),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer correction'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _fixDuplicateAdmins(true); // Correction réelle
    }
  }

  /// 🔧 Exécuter la correction des doublons
  Future<void> _fixDuplicateAdmins(bool applyFix) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(applyFix ? 'Correction en cours...' : 'Simulation en cours...'),
            const SizedBox(height: 8),
            const Text('Traitement des doublons...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      final result = await AdminDuplicateFixService.fixDuplicateAdmins(
        dryRun: !applyFix,
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Afficher le résultat
      _showFixResultDialog(result, applyFix);

      if (applyFix) {
        // Recharger les données après correction
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _loadData();
          }
        });
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📊 Afficher le résultat de la correction
  void _showFixResultDialog(Map<String, dynamic> result, bool wasApplied) {
    final fixedCompanies = result['fixedCompanies'] as int;
    final deactivatedAdmins = result['deactivatedAdmins'] as int;
    final fixedDetails = result['fixedDetails'] as List<Map<String, dynamic>>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: wasApplied ? Icons.check_circle_rounded : Icons.preview_rounded,
          text: wasApplied ? 'Correction terminée' : 'Simulation terminée',
          iconColor: wasApplied ? Colors.green : Colors.blue,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (wasApplied ? Colors.green : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (wasApplied ? Colors.green : Colors.blue).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wasApplied ? '✅ Correction appliquée' : '🔍 Simulation effectuée',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: wasApplied ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('🏢 Compagnies ${wasApplied ? 'corrigées' : 'à corriger'}: $fixedCompanies'),
                    Text('👤 Admins ${wasApplied ? 'désactivés' : 'à désactiver'}: $deactivatedAdmins'),
                  ],
                ),
              ),
              if (fixedDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Détails:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: fixedDetails.length,
                    itemBuilder: (context, index) {
                      final detail = fixedDetails[index];
                      final adminKept = detail['adminKept'] as Map<String, dynamic>;
                      final adminsDeactivated = detail['adminsDeactivated'] as List<Map<String, dynamic>>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🏢 ${detail['compagnieNom']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('✅ Admin gardé: ${adminKept['displayName']}'),
                              if (adminsDeactivated.isNotEmpty) ...[
                                Text('⚠️ Admins ${wasApplied ? 'désactivés' : 'à désactiver'}:'),
                                ...adminsDeactivated.map((admin) => Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text('• ${admin['displayName']}'),
                                )),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!wasApplied) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmFixDuplicateAdmins();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Appliquer correction'),
            ),
          ] else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  /// 🏢 Helper pour vérifier si une compagnie est active
  bool _isCompanyActive(Map<String, dynamic> company) {
    final status = company['status']?.toString().toLowerCase();
    return status == 'active' || status == 'actif' || status == null; // Par défaut active si pas de statut
  }

  /// 🎨 Helper pour créer un titre de dialogue sans overflow
  Widget _buildDialogTitle({
    required IconData icon,
    required String text,
    Color iconColor = const Color(0xFF059669),
    double fontSize = 16,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 🔐 Réinitialiser le mot de passe d'un admin spécifique
  Future<void> _resetAdminPassword(Map<String, dynamic> admin) async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: Icons.lock_reset_rounded,
          text: '🔐 Réinitialiser le mot de passe',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voulez-vous réinitialiser le mot de passe de :'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF059669).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 ${admin['displayName'] ?? '${admin['prenom']} ${admin['nom']}'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                  Text('📧 ${admin['email']}',
                    overflow: TextOverflow.ellipsis),
                  Text('🏢 ${admin['compagnieNom'] ?? 'Compagnie non définie'}',
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Un nouveau mot de passe sera généré automatiquement.\n'
              'L\'admin devra le changer à sa première connexion.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('🔐 Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Réinitialisation en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await PasswordResetService.resetAdminPassword(
        adminId: admin['id'],
        adminEmail: admin['email'],
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher les nouveaux identifiants
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🔐 Mot de passe réinitialisé',
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${result['message']}'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF059669).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔑 Nouveaux identifiants :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('👤 Admin: ${result['adminName']}'),
                        Text('📧 Email: ${result['adminEmail']}'),
                        Text('🏢 Compagnie: ${result['compagnieNom']}'),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔐 Nouveau mot de passe:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      result['newPassword'],
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: result['newPassword']));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Mot de passe copié !'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  tooltip: 'Copier le mot de passe',
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Important :\n'
                    '• Transmettez ces identifiants à l\'admin\n'
                    '• L\'admin devra changer son mot de passe à la première connexion\n'
                    '• Conservez ces informations en sécurité',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        final emailData = PasswordResetService.prepareEmailData(
                          adminName: result['adminName'],
                          adminEmail: result['adminEmail'],
                          compagnieNom: result['compagnieNom'],
                          newPassword: result['newPassword'],
                        );

                        // Copier les données email pour envoi manuel
                        Clipboard.setData(ClipboardData(text: emailData['textBody']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email copié pour envoi manuel !'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.email_rounded),
                      label: const Text('Copier email'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _loadData(); // Recharger les données
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Terminé'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: $e');
    }
  }

  /// 👤 Afficher le dialogue d'assignation d'admin
  Future<void> _showAssignAdminDialog(Map<String, dynamic> company) async {
    final availableAdmins = await CompanyManagementService.getAvailableAdminsForReassignment();

    if (availableAdmins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun admin disponible pour assignation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedAdminId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: Icons.person_add_rounded,
          text: 'Assigner un admin à ${company['nom']}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableAdmins.length,
            itemBuilder: (context, index) {
              final admin = availableAdmins[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF059669),
                  child: const Icon(Icons.person_rounded, color: Colors.white),
                ),
                title: Text(admin['displayName'] ?? 'Sans nom'),
                subtitle: Text(admin['email'] ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () => Navigator.of(context).pop(admin['id']),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedAdminId != null) {
      await _assignAdminToCompany(selectedAdminId, company['id']);
    }
  }

  /// 🔄 Assigner un admin à une compagnie
  Future<void> _assignAdminToCompany(String adminId, String compagnieId) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Assignation en cours...'),
            SizedBox(height: 8),
            Text('Désactivation des anciens admins...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      debugPrint('[ADMIN_ASSIGNMENT] 🔄 Début assignation admin $adminId à compagnie $compagnieId');

      final result = await CompanyManagementService.reassignAdminToCompany(
        newAdminId: adminId,
        compagnieId: compagnieId,
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        final previousAdminsDeactivated = result['previousAdminsDeactivated'] ?? 0;
        final message = previousAdminsDeactivated > 0
            ? 'Admin assigné avec succès à ${result['compagnieNom']}. ${previousAdminsDeactivated} ancien(s) admin(s) désactivé(s).'
            : 'Admin assigné avec succès à ${result['compagnieNom']}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        debugPrint('[ADMIN_ASSIGNMENT] ✅ Assignation réussie: $message');

        // Recharger les données avec un délai pour la synchronisation
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _loadData();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔄 Désactiver un admin pour permettre la réassignation
  Future<void> _deactivateAdminForReassignment(Map<String, dynamic> admin) async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: Icons.person_off_rounded,
          text: 'Désactiver pour réassignation',
          iconColor: Colors.orange,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voulez-vous désactiver cet admin pour permettre la réassignation ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 ${admin['displayName'] ?? '${admin['prenom']} ${admin['nom']}'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                  Text('📧 ${admin['email']}',
                    overflow: TextOverflow.ellipsis),
                  Text('🏢 ${admin['compagnieNom'] ?? 'Compagnie non définie'}',
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Cet admin sera désactivé et la compagnie pourra recevoir un nouvel admin.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Désactivation en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await CompanyManagementService.deactivateAdminForReassignment(
        adminId: admin['id'],
        compagnieId: admin['compagnieId'],
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Recharger les données
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔄 Activer/Désactiver une compagnie avec synchronisation admin
  Future<void> _toggleCompanyStatus(Map<String, dynamic> company) async {
    final currentStatus = _isCompanyActive(company);
    final newStatus = !currentStatus;

    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildDialogTitle(
          icon: newStatus ? Icons.play_circle_rounded : Icons.pause_circle_rounded,
          text: '${newStatus ? 'Activer' : 'Désactiver'} la compagnie',
          iconColor: newStatus ? Colors.green : Colors.orange,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous ${newStatus ? 'activer' : 'désactiver'} cette compagnie ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (newStatus ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (newStatus ? Colors.green : Colors.orange).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏢 ${company['nom'] ?? 'Nom non défini'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                  Text('👤 Admin: ${company['adminCompagnieNom'] ?? 'Aucun'}',
                    overflow: TextOverflow.ellipsis),
                  Text('📧 ${company['adminCompagnieEmail'] ?? 'Aucun email'}',
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync_rounded, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Text('🔄 Synchronisation automatique',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    newStatus
                        ? '✅ La compagnie ET son admin seront activés\n✅ L\'admin pourra se connecter'
                        : '⚠️ La compagnie ET son admin seront désactivés\n⚠️ L\'admin ne pourra plus se connecter',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus ? '✅ Activer' : '⚠️ Désactiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('${newStatus ? 'Activation' : 'Désactivation'} en cours...'),
            const SizedBox(height: 8),
            const Text('Synchronisation avec l\'admin...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      final result = await CompanyManagementService.toggleCompanyStatusWithSync(
        compagnieId: company['id'],
        newStatus: newStatus,
      );

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat de la synchronisation
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: _buildDialogTitle(
              icon: Icons.check_circle_rounded,
              text: 'Synchronisation réussie',
              iconColor: Colors.green,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ ${result['message']}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔄 Synchronisation effectuée:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      Text('🏢 Compagnie: ${newStatus ? 'Activée' : 'Désactivée'}'),
                      if (result['adminsUpdated'] > 0) ...[
                        Text('👤 Admin synchronisé: ${result['adminInfo']}'),
                        Text('📊 Statut admin: ${newStatus ? 'Actif' : 'Inactif'}'),
                      ] else
                        const Text('👤 Aucun admin à synchroniser'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  newStatus
                      ? '🎉 La compagnie et son admin sont maintenant actifs !'
                      : '⚠️ La compagnie et son admin sont maintenant inactifs.',
                  style: TextStyle(
                    color: newStatus ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Recharger les données avec un délai pour laisser le temps à Firestore de se synchroniser
                  debugPrint('[ADMIN_COMPAGNIE_LIST] 🔄 Programmation rechargement après synchronisation');
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (mounted) {
                      debugPrint('[ADMIN_COMPAGNIE_LIST] 🔄 Rechargement après synchronisation');
                      _loadData();
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔍 Navigation vers les détails d'un admin
  Future<void> _navigateToAdminDetails(Map<String, dynamic> admin) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminCompagnieDetailsScreen(
          adminId: admin['id'],
          adminName: admin['displayName'] ?? '${admin['prenom']} ${admin['nom']}',
        ),
      ),
    );

    // Recharger les données si des modifications ont été faites
    if (result == true) {
      await _loadData();
    }
  }

  /// 🔄 Activer/Désactiver un admin
  Future<void> _toggleAdminStatus(Map<String, dynamic> admin) async {
    final isActive = admin['isActive'] == true;
    final adminName = admin['displayName'] ?? '${admin['prenom']} ${admin['nom']}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? '🔒 Désactiver Admin' : '🔓 Activer Admin'),
        content: Text(
          isActive
              ? 'Voulez-vous désactiver le compte de $adminName ?\n\nIl ne pourra plus se connecter.'
              : 'Voulez-vous réactiver le compte de $adminName ?\n\nIl pourra à nouveau se connecter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange : Colors.green,
            ),
            child: Text(
              isActive ? 'Désactiver' : 'Activer',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = isActive
          ? await AdminCompagnieCrudService.deactivateAdminCompagnie(admin['id'])
          : await AdminCompagnieCrudService.reactivateAdminCompagnie(admin['id']);

      if (success) {
        await _loadData();
        _showSuccessSnackBar(
          isActive ? '🔒 Admin désactivé' : '🔓 Admin réactivé',
        );
      } else {
        _showErrorSnackBar('❌ Erreur lors de la modification du statut');
      }
    }
  }

  /// 🗑️ Confirmer la suppression d'un admin
  Future<void> _confirmDeleteAdmin(Map<String, dynamic> admin) async {
    final adminName = admin['displayName'] ?? '${admin['prenom']} ${admin['nom']}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Supprimer Admin'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement le compte de $adminName ?\n\n'
          '⚠️ Cette action est irréversible et supprimera :\n'
          '• Le compte utilisateur\n'
          '• L\'assignation à la compagnie\n'
          '• Tous les logs associés',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminCompagnieCrudService.deleteAdminCompagnie(admin['id']);
      if (success) {
        await _loadData();
        _showSuccessSnackBar('🗑️ Admin supprimé avec succès');
      } else {
        _showErrorSnackBar('❌ Erreur lors de la suppression');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }



  /// 🔗 CORRIGER LES LIAISONS EXISTANTES
  Future<void> _fixExistingLinks() async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Colors.green),
            SizedBox(width: 12),
            Text('🔗 Corriger les liaisons'),
          ],
        ),
        content: const Text(
          '🔗 CORRECTION DES LIAISONS\n\n'
          'Cette action va :\n\n'
          '✅ Vérifier toutes les compagnies\n'
          '✅ Corriger les liaisons admin-compagnie\n'
          '✅ Synchroniser les champs hasAdmin\n'
          '✅ Mettre à jour les statistiques\n\n'
          'Cela va résoudre le problème d\'affichage\n'
          'des compagnies avec admin.\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('🔗 Corriger'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('🔗 Correction en cours...'),
            SizedBox(height: 8),
            Text('Vérification et correction des liaisons...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      // Effectuer la correction des liaisons
      final result = await CompanyStructureService.fixMissingAdminLinks();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('🔗 Liaisons corrigées'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${result['message']}'),
                  const SizedBox(height: 16),
                  if (result['fixedLinks'] != null && result['fixedLinks'] > 0) ...[
                    Text('🔗 Liaisons corrigées: ${result['fixedLinks']}'),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    '🎯 LIAISONS CORRIGÉES !\n\n'
                    '✅ Votre compagnie devrait maintenant\n'
                    '    apparaître dans "Compagnies avec Admin"\n'
                    '✅ Les statistiques sont mises à jour\n'
                    '✅ L\'affichage est cohérent\n\n'
                    '🔄 Rechargez les données pour voir les changements',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('🔄 Recharger'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: $e');
    }
  }

  /// 🎯 SUPPRIMER UNIQUEMENT LES DONNÉES CRÉÉES AUTOMATIQUEMENT
  Future<void> _deleteAutoCreatedData() async {
    // Confirmation ciblée
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_delete_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🎯 Supprimer données automatiques',
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          '🎯 SUPPRESSION CIBLÉE\n\n'
          'Cette action va supprimer UNIQUEMENT :\n\n'
          '🗑️ Les 12 compagnies créées par le CODE\n'
          '🗑️ Les 7 compagnies générées automatiquement\n'
          '🗑️ Les admins créés automatiquement\n\n'
          '✅ CONSERVE vos créations manuelles\n'
          '✅ Garde vos données personnelles\n\n'
          '📋 Critères de suppression :\n'
          '• createdBy = "system_init" ou "super_admin"\n'
          '• Noms génériques (BIAT, Salim, STAR, etc.)\n'
          '• Admins avec source = "super_admin_creation"\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('🎯 Supprimer données auto'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('🎯 Suppression ciblée...'),
            SizedBox(height: 8),
            Text('Suppression des données automatiques uniquement...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      // Effectuer la suppression ciblée
      final result = await DatabaseCleanupService.deleteCodeCreatedData();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🎯 Suppression ciblée terminée',
                    style: TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${result['message']}'),
                  const SizedBox(height: 16),
                  Text('📊 SUPPRIMÉ :'),
                  for (final entry in (result['deletedCounts'] as Map<String, int>).entries)
                    if (entry.value > 0)
                      Text('  • ${entry.key}: ${entry.value} éléments'),
                  const SizedBox(height: 16),
                  const Text(
                    '🎯 DONNÉES AUTOMATIQUES SUPPRIMÉES !\n\n'
                    '✅ Vos créations manuelles sont conservées\n'
                    '✅ Les listes sont maintenant cohérentes\n'
                    '✅ Une seule collection "compagnies"\n'
                    '✅ Même données dans les 2 interfaces\n\n'
                    '🚀 Vous pouvez maintenant créer vos compagnies\n'
                    'et elles apparaîtront partout !',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('✅ Parfait !'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: $e');
    }
  }

  /// 🔥 SUPPRIMER TOUT DÉFINITIVEMENT
  Future<void> _deleteAllDefinitively() async {
    // Confirmation très stricte
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('🔥 SUPPRIMER TOUT', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          '🚨 SUPPRESSION DÉFINITIVE 🚨\n\n'
          'Cette action va SUPPRIMER DÉFINITIVEMENT :\n\n'
          '🗑️ LES 12 COMPAGNIES de "Gestion des Compagnies"\n'
          '🗑️ LES 7 COMPAGNIES de "Gestion des Utilisateurs"\n'
          '🗑️ TOUS les admins compagnie\n'
          '🗑️ TOUTES les collections de compagnies\n\n'
          '✅ Résultat : BASE DE DONNÉES VIDE\n'
          '✅ Prêt pour création manuelle\n'
          '✅ Une seule collection unifiée\n\n'
          '⚠️ CETTE ACTION EST IRRÉVERSIBLE !\n\n'
          'Voulez-vous VRAIMENT tout supprimer ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('❌ NON, ANNULER', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('🔥 OUI, SUPPRIMER TOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('🔥 SUPPRESSION EN COURS...'),
            SizedBox(height: 8),
            Text('Suppression définitive de tout...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      // Effectuer la suppression agressive
      final result = await DatabaseCleanupService.aggressiveCleanup();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat de suppression
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('🎯 SUPPRESSION TERMINÉE'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${result['message']}'),
                  const SizedBox(height: 16),
                  Text('📊 DÉTAILS :'),
                  Text('• Total supprimé: ${result['totalDeleted']} éléments'),
                  const SizedBox(height: 8),
                  const Text('🗑️ SUPPRIMÉ :'),
                  for (final entry in (result['deletedCounts'] as Map<String, int>).entries)
                    if (entry.value > 0)
                      Text('  • ${entry.key}: ${entry.value} éléments'),
                  const SizedBox(height: 16),
                  const Text(
                    '🎯 BASE DE DONNÉES NETTOYÉE !\n\n'
                    '✅ Maintenant vous pouvez :\n'
                    '1️⃣ Créer vos compagnies manuellement\n'
                    '2️⃣ Elles apparaîtront dans les 2 listes\n'
                    '3️⃣ Une seule collection "compagnies"\n'
                    '4️⃣ Plus de problèmes de synchronisation !',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('🚀 COMMENCER À CRÉER'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: $e');
    }
  }

  /// 🔄 UNIFIER MAINTENANT - Nettoyer et utiliser une seule collection
  Future<void> _unifyNow() async {
    // Confirmation simple
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.merge_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('🔄 UNIFIER MAINTENANT'),
          ],
        ),
        content: const Text(
          '🎯 UNIFICATION VERS UNE SEULE COLLECTION\n\n'
          'Cette action va :\n\n'
          '🧹 Nettoyer toutes les collections existantes\n'
          '🔄 Unifier vers la collection "compagnies"\n'
          '✅ Permettre la création manuelle unifiée\n\n'
          '📋 Résultat :\n'
          '• Gestion des Compagnies → collection "compagnies"\n'
          '• Gestion des Utilisateurs → collection "compagnies"\n'
          '• Plus de problèmes de synchronisation !\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('🔄 UNIFIER'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🔄 Unification en cours...'),
            SizedBox(height: 8),
            Text('Nettoyage et préparation...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      // Effectuer le nettoyage complet
      final result = await DatabaseCleanupService.fullCleanup();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat d'unification
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('🎯 UNIFICATION TERMINÉE'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ ${result['message']}'),
                const SizedBox(height: 16),
                const Text(
                  '🎯 COLLECTION UNIFIÉE : "compagnies"\n\n'
                  '✅ Maintenant tout utilise la même collection :\n'
                  '• Gestion des Compagnies\n'
                  '• Gestion des Utilisateurs\n'
                  '• Création d\'admins\n\n'
                  '🚀 PRÊT POUR CRÉATION MANUELLE :\n'
                  '1️⃣ Créer compagnie → Visible partout\n'
                  '2️⃣ Affecter admin → Liaison automatique\n'
                  '3️⃣ Plus de problèmes de synchronisation !',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('🎯 COMMENCER'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: $e');
    }
  }

  /// 🗑️ Nettoyage rapide (une seule confirmation)
  Future<void> _quickCleanup() async {
    // Une seule confirmation simple
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Nettoyage rapide'),
          ],
        ),
        content: const Text(
          '🧹 NETTOYAGE RAPIDE\n\n'
          'Cette action va supprimer :\n\n'
          '🗑️ Toutes les compagnies (collections: compagnies, compagnies_assurance)\n'
          '🗑️ Tous les admins compagnie\n\n'
          '✅ Vous pourrez ensuite recréer manuellement\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Nettoyer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🧹 Nettoyage en cours...'),
          ],
        ),
      ),
    );

    try {
      // Effectuer le nettoyage
      final result = await DatabaseCleanupService.fullCleanup();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat simple
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('✅ Nettoyage terminé'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎯 ${result['message']}'),
                const SizedBox(height: 16),
                const Text(
                  '📋 PRÊT POUR CRÉATION MANUELLE :\n\n'
                  '1️⃣ Gestion des Compagnies → Ajouter compagnie\n'
                  '2️⃣ Gestion des Utilisateurs → Créer admin\n\n'
                  '✅ Les 2 listes seront maintenant séparées',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur: $e');
    }
  }

  /// 🔍 Diagnostic des collections
  Future<void> _diagnoseCollections() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Diagnostic en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await DatabaseCleanupService.diagnoseCollections();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        final diagnosis = result['diagnosis'] as Map<String, dynamic>;

        // Afficher le diagnostic détaillé
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.purple),
                SizedBox(width: 12),
                Text('🔍 Diagnostic des Collections'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in diagnosis.entries) ...[
                    Text(
                      '📋 ${entry.key.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    if (entry.value['error'] != null) ...[
                      Text('❌ Erreur: ${entry.value['error']}',
                        style: const TextStyle(color: Colors.red)),
                    ] else if (entry.key == 'users') ...[
                      Text('👥 Total utilisateurs: ${entry.value['total']}'),
                      Text('🏢 Admins compagnie: ${entry.value['adminCompagnie']}'),
                    ] else ...[
                      Text('📊 Total: ${entry.value['total']} documents'),
                      if (entry.value['documents'] != null && entry.value['documents'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        for (final doc in entry.value['documents']) ...[
                          Text('  • ${doc['nom']} (${doc['id']})',
                            style: const TextStyle(fontSize: 12)),
                        ],
                      ],
                    ],
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur diagnostic: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors du diagnostic: $e');
    }
  }

  /// 🧹 NETTOYAGE COMPLET DE LA BASE DE DONNÉES
  Future<void> _fullDatabaseCleanup() async {
    // Afficher une boîte de dialogue de confirmation TRÈS stricte
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('⚠️ NETTOYAGE COMPLET', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          '🚨 ATTENTION - ACTION IRRÉVERSIBLE ! 🚨\n\n'
          'Cette action va SUPPRIMER DÉFINITIVEMENT :\n\n'
          '🗑️ TOUTES les compagnies de TOUTES les collections\n'
          '🗑️ TOUS les admins compagnie\n'
          '🗑️ TOUTES les liaisons admin-compagnie\n\n'
          '📋 Collections affectées :\n'
          '• compagnies\n'
          '• compagnies_assurance\n'
          '• companies\n'
          '• insurance_companies\n'
          '• users (admins compagnie uniquement)\n\n'
          '⚠️ CETTE ACTION EST IRRÉVERSIBLE !\n'
          '⚠️ VOUS DEVREZ TOUT RECRÉER MANUELLEMENT !\n\n'
          'Êtes-vous ABSOLUMENT SÛR ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('❌ ANNULER', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('🗑️ SUPPRIMER TOUT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Deuxième confirmation
    final doubleConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 DERNIÈRE CONFIRMATION', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Vous êtes sur le point de SUPPRIMER DÉFINITIVEMENT :\n\n'
          '• Toutes les compagnies\n'
          '• Tous les admins compagnie\n'
          '• Toutes les données associées\n\n'
          'Cette action est IRRÉVERSIBLE !\n\n'
          'Tapez "SUPPRIMER" pour confirmer :',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMER LA SUPPRESSION'),
          ),
        ],
      ),
    );

    if (doubleConfirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('🧹 NETTOYAGE EN COURS...'),
            SizedBox(height: 8),
            Text('Suppression de toutes les données...',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      // Effectuer le nettoyage complet
      final result = await DatabaseCleanupService.fullCleanup();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat détaillé
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('🧹 NETTOYAGE TERMINÉ'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${result['message']}'),
                  const SizedBox(height: 16),
                  Text('📊 RÉSUMÉ :'),
                  Text('• Compagnies supprimées: ${result['companiesDeleted']}'),
                  Text('• Admins supprimés: ${result['adminsDeleted']}'),
                  Text('• Total supprimé: ${result['totalDeleted']} éléments'),
                  const SizedBox(height: 16),
                  const Text(
                    '🎯 BASE DE DONNÉES NETTOYÉE !\n\n'
                    'Vous pouvez maintenant :\n'
                    '1. Créer vos compagnies manuellement\n'
                    '2. Affecter des admins à chaque compagnie\n'
                    '3. Tout sera unifié dans la même collection',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur lors du nettoyage: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors du nettoyage: $e');
    }
  }

  /// 🗑️ Vider toutes les compagnies
  Future<void> _clearAllCompanies() async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Vider la collection'),
          ],
        ),
        content: const Text(
          '⚠️ ATTENTION !\n\n'
          'Cette action va supprimer TOUTES les compagnies '
          'de la collection "compagnies_assurance".\n\n'
          'Cela va également :\n'
          '• Supprimer les liaisons avec les admins\n'
          '• Vider la liste des compagnies partout\n'
          '• Permettre l\'ajout manuel de nouvelles compagnies\n\n'
          'Cette action est IRRÉVERSIBLE !\n\n'
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Suppression en cours...'),
          ],
        ),
      ),
    );

    try {
      // Appeler la méthode de suppression
      final result = await CompanyManagementService.clearAllCompanies();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Collection vidée'),
              ],
            ),
            content: Text(
              '✅ ${result['message']}\n\n'
              '📊 Compagnies supprimées: ${result['companiesDeleted']}\n\n'
              '🎯 Vous pouvez maintenant ajouter vos compagnies '
              'manuellement via la gestion des compagnies.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de la suppression: $e');
    }
  }

  /// 🏗️ Créer les compagnies par défaut
  Future<void> _createDefaultCompanies() async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.factory_rounded, color: Colors.green),
            SizedBox(width: 12),
            Text('Créer compagnies par défaut'),
          ],
        ),
        content: const Text(
          'Cette action va créer 5 compagnies d\'assurance tunisiennes '
          'dans la collection "compagnies_assurance".\n\n'
          'Ces compagnies seront disponibles dans :\n'
          '• Gestion des compagnies\n'
          '• Gestion des utilisateurs (création admin)\n\n'
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Création des compagnies...'),
          ],
        ),
      ),
    );

    try {
      // Diagnostic d'abord
      final diagnostic = await CompanyManagementService.diagnoseCollection();

      if (diagnostic['success'] && diagnostic['count'] > 0) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 12),
                Text('Collection non vide'),
              ],
            ),
            content: Text(
              'La collection contient déjà ${diagnostic['count']} compagnies.\n\n'
              'Compagnies existantes:\n'
              '${diagnostic['companies'].map((c) => '• ${c['nom']}').join('\n')}'
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Créer les compagnies par défaut
      final result = await CompanyManagementService.createDefaultCompanies();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Compagnies créées'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${result['message']}'),
                  const SizedBox(height: 16),
                  const Text('🏢 Compagnies créées:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...result['createdCompanies'].map<Widget>((company) =>
                    Text('• $company', style: const TextStyle(fontSize: 12))),
                  const SizedBox(height: 16),
                  const Text(
                    '✅ Ces compagnies sont maintenant disponibles dans :\n'
                    '• Gestion des compagnies\n'
                    '• Gestion des utilisateurs (création admin)',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur: ${result['error'] ?? result['message']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de la création: $e');
    }
  }

  /// 🏗️ Recréer la collection compagnies_assurance
  Future<void> _recreateCompaniesCollection() async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Recréer la collection'),
          ],
        ),
        content: const Text(
          '⚠️ ATTENTION !\n\n'
          'Cette action va recréer la collection "compagnies_assurance" '
          'avec des compagnies par défaut.\n\n'
          'Cela va :\n'
          '• Créer 5 compagnies d\'assurance tunisiennes\n'
          '• Migrer automatiquement les admins existants\n'
          '• Corriger les liaisons admin-compagnie\n\n'
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recréer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recréation de la collection...'),
            SizedBox(height: 8),
            Text('Cela peut prendre quelques secondes',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    try {
      // Étape 1: Recréer la collection
      final recreateResult = await CompanyStructureService.recreateCompaniesCollection();

      if (!recreateResult['success']) {
        Navigator.of(context).pop();
        _showErrorSnackBar('Erreur recréation: ${recreateResult['error']}');
        return;
      }

      // Étape 2: Migrer les admins existants
      final migrateResult = await CompanyStructureService.migrateExistingAdmins();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      // Afficher le résultat
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Collection recréée'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ ${recreateResult['message']}'),
                const SizedBox(height: 8),
                Text('📊 Compagnies créées: ${recreateResult['companiesCreated']}'),

                if (recreateResult['createdCompanies'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('🏢 Compagnies créées:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  ...recreateResult['createdCompanies'].map<Widget>((company) =>
                    Text('• $company', style: const TextStyle(fontSize: 12))),
                ],

                if (migrateResult['success']) ...[
                  const SizedBox(height: 12),
                  Text('🔄 ${migrateResult['message']}'),
                  if (migrateResult['migratedAdmins'].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('👤 Admins migrés:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    ...migrateResult['migratedAdmins'].map<Widget>((admin) =>
                      Text('• $admin', style: const TextStyle(fontSize: 12))),
                  ],
                ],

                if (recreateResult['errors'].isNotEmpty ||
                    (migrateResult['errors'] != null && migrateResult['errors'].isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  const Text('⚠️ Erreurs:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ...recreateResult['errors'].map<Widget>((error) =>
                    Text('• $error', style: const TextStyle(fontSize: 12, color: Colors.orange))),
                  if (migrateResult['errors'] != null)
                    ...migrateResult['errors'].map<Widget>((error) =>
                      Text('• $error', style: const TextStyle(fontSize: 12, color: Colors.orange))),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadData(); // Recharger les données
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de la recréation: $e');
    }
  }

  /// 🔍 Chercher les compagnies dans toutes les collections
  Future<void> _searchCompaniesInAllCollections() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Recherche dans toutes les collections...'),
          ],
        ),
      ),
    );

    try {
      // Appeler la méthode de recherche
      final result = await CompanyStructureService.findCompaniesInAllCollections();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        final companiesByCollection = result['companiesByCollection'] as Map<String, dynamic>;
        final biatCompanies = result['biatCompanies'] as Map<String, dynamic>;

        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.folder_open_rounded, color: Colors.purple),
                SizedBox(width: 12),
                Text('Collections trouvées'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Collections avec données: ${result['collectionsWithData']}/${result['totalCollections']}'),
                  const SizedBox(height: 16),

                  if (companiesByCollection.isNotEmpty) ...[
                    const Text('📋 Collections trouvées:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...companiesByCollection.entries.map<Widget>((entry) {
                      final collectionName = entry.key;
                      final companies = entry.value as List;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(collectionName),
                          subtitle: Text('${companies.length} compagnies'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showCollectionDetails(collectionName, companies);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Voir'),
                          ),
                        ),
                      );
                    }),
                  ],

                  if (biatCompanies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('🎯 "Assurances BIAT" trouvée dans:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    ...biatCompanies.entries.map<Widget>((entry) {
                      final collectionName = entry.key;
                      final companies = entry.value as List;
                      return Text('• $collectionName (${companies.length} matches)');
                    }),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur lors de la recherche: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de la recherche: $e');
    }
  }

  /// 📋 Afficher les détails d'une collection
  void _showCollectionDetails(String collectionName, List companies) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Collection: $collectionName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 ${companies.length} compagnies trouvées:'),
              const SizedBox(height: 16),
              ...companies.take(10).map<Widget>((company) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 ${company['nom']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('ID: ${company['id']}'),
                      Text('Admin: ${company['adminCompagnieNom'] ?? 'AUCUN'}'),
                    ],
                  ),
                ),
              )),
              if (companies.length > 10)
                Text('... et ${companies.length - 10} autres'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _useThisCollection(collectionName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Utiliser cette collection'),
          ),
        ],
      ),
    );
  }

  /// 🔧 Utiliser une collection spécifique
  void _useThisCollection(String collectionName) {
    CompanyStructureService.setCompanyCollection(collectionName);
    _showSuccessSnackBar('Collection mise à jour: $collectionName');
    _loadData(); // Recharger les données
  }



  /// 🔍 Détecter les compagnies en double
  Future<void> _detectDuplicates() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Détection des doublons...'),
          ],
        ),
      ),
    );

    try {
      // Appeler la méthode de détection
      final result = await CompanyStructureService.detectDuplicateCompanies();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        final duplicates = result['duplicates'] as List;
        final duplicatesCount = result['duplicatesCount'] as int;

        if (duplicatesCount == 0) {
          // Aucun doublon trouvé
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Aucun doublon'),
                ],
              ),
              content: Text('✅ Aucune compagnie en double détectée.\n\n'
                'Total: ${result['totalCompanies']} compagnies\n'
                'Noms uniques: ${result['uniqueNames']}'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Doublons trouvés
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text('$duplicatesCount doublons détectés'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚨 $duplicatesCount groupes de compagnies en double trouvés:'),
                    const SizedBox(height: 16),
                    ...duplicates.map<Widget>((duplicate) {
                      final companies = duplicate['companies'] as List;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '📋 ${duplicate['nom']} (${duplicate['count']} instances)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...companies.map<Widget>((company) => Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 4),
                                child: Text(
                                  '• ID: ${company['id']}\n'
                                  '  Admin: ${company['adminCompagnieNom'] ?? 'AUCUN'}\n'
                                  '  Status: ${company['status']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDuplicateFixDialog(duplicates);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Corriger'),
                ),
              ],
            ),
          );
        }
      } else {
        _showErrorSnackBar('Erreur lors de la détection: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de la détection: $e');
    }
  }

  /// 🔧 Afficher le dialogue de correction des doublons
  void _showDuplicateFixDialog(List duplicates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Correction des doublons'),
        content: const Text(
          'Pour corriger les doublons, vous devez choisir quelle compagnie garder '
          'et lesquelles supprimer pour chaque groupe.\n\n'
          'Cette opération est irréversible. Voulez-vous continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'interface de correction
              _showErrorSnackBar('Fonctionnalité de correction en cours de développement');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  /// 🔍 Diagnostiquer les compagnies sans admin
  Future<void> _diagnoseCompanies() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Diagnostic en cours...'),
          ],
        ),
      ),
    );

    try {
      // Appeler la méthode de diagnostic
      final result = await CompanyStructureService.diagnoseCompaniesWithoutAdmin();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        final companiesWithoutAdmin = result['companiesWithoutAdmin'] as List;
        final companiesWithAdmin = result['companiesWithAdmin'] as List;
        final summary = result['summary'] as Map<String, dynamic>;

        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.search_rounded, color: Color(0xFF059669)),
                SizedBox(width: 12),
                Text('Diagnostic des compagnies'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Total: ${result['totalCompanies']} compagnies'),
                  Text('✅ Avec admin: ${summary['withAdmin']}'),
                  Text('❌ Sans admin: ${summary['withoutAdmin']}'),

                  if (companiesWithoutAdmin.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('🚨 Compagnies sans admin:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 8),
                    ...companiesWithoutAdmin.map<Widget>((company) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${company['nom']} (ID: ${company['id']})'),
                      ),
                    ),
                  ],

                  if (companiesWithAdmin.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('✅ Compagnies avec admin:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    ...companiesWithAdmin.take(5).map<Widget>((company) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${company['nom']} → ${company['adminCompagnieNom']}'),
                      ),
                    ),
                    if (companiesWithAdmin.length > 5)
                      Text('... et ${companiesWithAdmin.length - 5} autres'),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur lors du diagnostic: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors du diagnostic: $e');
    }
  }

  /// 🔧 Corriger les liaisons admin-compagnie manquantes
  Future<void> _fixAdminLinks() async {
    // Afficher une boîte de dialogue de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.build_rounded, color: Color(0xFF059669)),
            SizedBox(width: 12),
            Text('Corriger les liaisons'),
          ],
        ),
        content: const Text(
          'Cette action va corriger les liaisons manquantes entre les admins compagnie et leurs compagnies.\n\n'
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            child: const Text('Corriger'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Correction en cours...'),
          ],
        ),
      ),
    );

    try {
      // Appeler la méthode de correction
      final result = await CompanyStructureService.fixMissingAdminLinks();

      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();

      if (result['success']) {
        // Afficher le résultat
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Correction terminée'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ ${result['message']}'),
                const SizedBox(height: 8),
                Text('📊 Compagnies vérifiées: ${result['companiesChecked']}'),
                Text('🔧 Compagnies corrigées: ${result['companiesFixed']}'),
                if (result['errors'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('⚠️ Erreurs:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...result['errors'].map<Widget>((error) => Text('• $error')),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Recharger les données
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar('Erreur lors de la correction: ${result['error']}');
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      Navigator.of(context).pop();
      _showErrorSnackBar('Erreur lors de la correction: $e');
    }
  }
}
