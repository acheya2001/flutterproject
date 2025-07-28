import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_compagnie_agence_service.dart';
import 'create_agence_only_screen.dart';
import 'create_admin_agence_screen.dart';
import 'create_admin_agence_auto_screen.dart';
import 'agence_details_screen.dart';
import 'edit_agence_screen.dart';
import 'assign_admin_agence_screen.dart';
import '../../../services/admin_agence_management_service.dart';

/// 🏢 Écran moderne de gestion des agences
class ModernAgenceManagementScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ModernAgenceManagementScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<ModernAgenceManagementScreen> createState() => _ModernAgenceManagementScreenState();
}

class _ModernAgenceManagementScreenState extends State<ModernAgenceManagementScreen> {
  List<Map<String, dynamic>> _agences = [];
  List<Map<String, dynamic>> _filteredAgences = [];
  bool _isLoading = true;
  
  // Contrôleurs de recherche et filtres
  final _searchController = TextEditingController();
  String _selectedStatut = 'Tous';
  String _selectedGouvernorat = 'Tous';
  String _selectedAdminStatus = 'Tous';
  
  final List<String> _statutOptions = ['Tous', 'Occupé', 'Libre', 'Désactivé'];
  final List<String> _adminStatusOptions = ['Tous', 'Avec Admin', 'Sans Admin'];
  final List<String> _gouvernoratOptions = [
    'Tous', 'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan', 
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse', 'Monastir', 
    'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès', 
    'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  @override
  void initState() {
    super.initState();
    _loadAgences();
    _searchController.addListener(_filterAgences);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📊 Charger les agences
  Future<void> _loadAgences() async {
    setState(() => _isLoading = true);
    
    try {
      final agences = await AdminCompagnieAgenceService.getAgencesWithAdminStatus(
        widget.userData['compagnieId']
      );
      
      _agences = agences;
      _filterAgences();
    } catch (e) {
      debugPrint('Erreur chargement agences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filtrer les agences
  void _filterAgences() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredAgences = _agences.where((agence) {
        final nomMatch = agence['nom']?.toLowerCase().contains(query) ?? false;
        final adresseMatch = agence['adresse']?.toLowerCase().contains(query) ?? false;
        final codeMatch = agence['code']?.toLowerCase().contains(query) ?? false;
        
        final statutMatch = _selectedStatut == 'Tous' || 
            _getStatutDisplay(agence).toLowerCase() == _selectedStatut.toLowerCase();
        
        final gouvernoratMatch = _selectedGouvernorat == 'Tous' || 
            agence['gouvernorat']?.toString() == _selectedGouvernorat;
        
        final adminMatch = _selectedAdminStatus == 'Tous' ||
            (_selectedAdminStatus == 'Avec Admin' && agence['hasAdminAgence'] == true) ||
            (_selectedAdminStatus == 'Sans Admin' && agence['hasAdminAgence'] != true);
        
        return (nomMatch || adresseMatch || codeMatch) && statutMatch && gouvernoratMatch && adminMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 🎨 AppBar moderne
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Text(
        'Agences - ${widget.userData['compagnieNom']}',
        style: const TextStyle(
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
            colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _loadAgences,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
        ),
        IconButton(
          onPressed: () => _showStatsDialog(),
          icon: const Icon(Icons.analytics_rounded, color: Colors.white),
          tooltip: 'Statistiques',
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des agences...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    return Column(
      children: [
        // Barre de recherche et filtres
        _buildSearchAndFilters(),
        
        // Statistiques rapides
        _buildQuickStats(),
        
        // Liste des agences
        Expanded(
          child: _filteredAgences.isEmpty 
              ? _buildEmptyState() 
              : _buildAgencesList(),
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche et filtres compacts
  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de recherche compacte
          SizedBox(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF059669), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterAgences();
                        },
                        icon: const Icon(Icons.clear_rounded, size: 18),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filtres compacts en une seule ligne
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCompactFilterDropdown(
                  'Statut',
                  _selectedStatut,
                  _statutOptions,
                  (value) => setState(() {
                    _selectedStatut = value!;
                    _filterAgences();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildCompactFilterDropdown(
                  'Admin',
                  _selectedAdminStatus,
                  _adminStatusOptions,
                  (value) => setState(() {
                    _selectedAdminStatus = value!;
                    _filterAgences();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildCompactFilterDropdown(
                  'Gouvernorat',
                  _selectedGouvernorat,
                  _gouvernoratOptions,
                  (value) => setState(() {
                    _selectedGouvernorat = value!;
                    _filterAgences();
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Statistiques rapides
  Widget _buildQuickStats() {
    final totalAgences = _agences.length;
    final avecAdmin = _agences.where((a) => a['hasAdminAgence'] == true).length;
    final sansAdmin = _agences.where((a) => a['hasAdminAgence'] != true).length;
    final actives = _agences.where((a) => a['isActive'] != false).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalAgences.toString(),
              Icons.business_rounded,
              const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Avec Admin',
              avecAdmin.toString(),
              Icons.admin_panel_settings_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Sans Admin',
              sansAdmin.toString(),
              Icons.person_off_rounded,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Actives',
              actives.toString(),
              Icons.check_circle_rounded,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires manquantes
  String _getStatutDisplay(Map<String, dynamic> agence) {
    if (agence['hasAdminAgence'] == true) {
      return 'Occupé';
    } else {
      return 'Libre';
    }
  }

  List<Color> _getAgenceGradient(Map<String, dynamic> agence) {
    if (agence['isActive'] == false) {
      return [const Color(0xFFEF4444), const Color(0xFFDC2626)]; // Rouge pour désactivé
    } else if (agence['hasAdminAgence'] == true) {
      return [const Color(0xFF10B981), const Color(0xFF059669)]; // Vert pour occupé
    } else {
      return [const Color(0xFFF59E0B), const Color(0xFFD97706)]; // Orange pour libre
    }
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      onChanged: onChanged,
    );
  }

  /// 🔽 Dropdown compact pour les filtres
  Widget _buildCompactFilterDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(
              option,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          )).toList(),
          onChanged: onChanged,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune agence trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première agence ou modifiez vos filtres',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateAgenceDialog(),
      backgroundColor: const Color(0xFF059669),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nouvelle Agence'),
    );
  }

  Widget _buildAgencesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAgences.length,
      itemBuilder: (context, index) {
        final agence = _filteredAgences[index];
        return _buildAgenceCard(agence);
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF059669),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Actions et méthodes
  void _showStatsDialog() {
    // TODO: Implémenter les statistiques détaillées
  }

  void _showCreateAgenceDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAgenceOnlyScreen(userData: widget.userData),
      ),
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Agence créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAgences();
    }
  }

  /// 👁️ Afficher les détails de l'agence
  void _showAgenceDetails(Map<String, dynamic> agence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgenceDetailsScreen(
          agenceData: agence,
          userData: widget.userData,
        ),
      ),
    );

    if (result != null) {
      await _loadAgences();
    }
  }

  /// ✏️ Modifier l'agence
  void _showEditAgenceDialog(Map<String, dynamic> agence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAgenceScreen(
          agenceData: agence,
          userData: widget.userData,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Agence modifiée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAgences();
    }
  }

  /// 🔗 Affecter un admin existant à une agence
  void _assignAdminToAgence(Map<String, dynamic> agence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignAdminAgenceScreen(
          userData: widget.userData,
          agenceData: agence,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Admin affecté avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAgences();
    }
  }

  /// 👨‍💼 Créer un nouvel admin pour une agence (option alternative)
  void _createAdminForAgence(Map<String, dynamic> agence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAdminAgenceAutoScreen(
          userData: widget.userData,
          agenceData: agence,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Admin agence créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAgences();
    }
  }

  /// 🔧 Gérer l'admin agence
  void _manageAdminAgence(Map<String, dynamic> agence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAdminManagementSheet(agence),
    );
  }

  /// 🔄 Réinitialiser le mot de passe de l'admin
  void _resetAdminPassword(Map<String, dynamic> agence) async {
    final adminData = agence['adminAgence'];
    if (adminData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Text(
          'Voulez-vous réinitialiser le mot de passe de ${adminData['prenom']} ${adminData['nom']} ?\n\n'
          'Un nouveau mot de passe sera généré et envoyé par email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await AdminAgenceManagementService.resetAdminPassword(
          adminId: adminData['id'],
          adminEmail: adminData['email'],
          adminName: '${adminData['prenom']} ${adminData['nom']}',
          agenceName: agence['nom'] ?? 'Agence',
        );

        if (result['success']) {
          // Afficher le dialogue avec le nouveau mot de passe
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mot de passe réinitialisé',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔑 Nouveau mot de passe :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          result['newPassword'],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (result['emailSent'] == true) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.email, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email envoyé à l\'admin',
                              style: TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Erreur envoi email - Communiquez le mot de passe manuellement',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Copier dans le presse-papiers si possible
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🗑️ Retirer l'admin de l'agence
  void _removeAdminFromAgence(Map<String, dynamic> agence) async {
    final adminData = agence['adminAgence'];
    if (adminData == null) return;

    // Demander la raison du retrait avec dialogue sécurisé
    final reason = await _showRemoveAdminDialog(adminData);
    if (reason == null) return;

    try {
      final result = await AdminAgenceManagementService.removeAdminFromAgence(
        adminId: adminData['id'],
        agenceId: agence['id'],
        reason: reason,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAgences();

        // Proposer d'affecter un autre admin
        _showAssignAdminDialog(agence);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🗑️ Dialogue de retrait d'admin
  Future<String?> _showRemoveAdminDialog(Map<String, dynamic> adminData) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Retirer l\'admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voulez-vous retirer ${adminData['prenom']} ${adminData['nom']} de cette agence ?\n\n'
              'L\'admin sera désactivé et l\'agence redeviendra libre.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du retrait',
                border: OutlineInputBorder(),
                hintText: 'Expliquez pourquoi vous retirez cet admin...',
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(context, reason.isEmpty ? 'Retiré par admin compagnie' : reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    // Nettoyer le contrôleur après utilisation
    reasonController.dispose();
    return result;
  }

  /// ⚡ Changer le statut de l'agence
  void _toggleAgenceStatus(Map<String, dynamic> agence) async {
    final isActive = agence['isActive'] != false;
    final newStatus = !isActive;

    // Demander confirmation avec raison si désactivation
    String? reason;

    if (!newStatus) {
      // Pour la désactivation, utiliser un dialogue personnalisé
      final result = await _showDeactivationDialog(agence['nom']);
      if (result == null) return;

      reason = result;
    } else {
      // Pour l'activation, dialogue simple
      final confirmed = await _showActivationDialog(agence['nom']);
      if (!confirmed) return;
    }

    // Effectuer le changement de statut
    await _performStatusChange(agence, newStatus, reason);
  }

  /// 🚫 Dialogue de désactivation avec raison
  Future<String?> _showDeactivationDialog(String agenceName) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver l\'agence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voulez-vous désactiver l\'agence "$agenceName" ?\n\n'
              '⚠️ Cela désactivera aussi son admin et tous ses agents.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de la désactivation',
                border: OutlineInputBorder(),
                hintText: 'Expliquez pourquoi vous désactivez cette agence...',
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(context, reason.isEmpty ? 'Désactivée par admin' : reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    // Nettoyer le contrôleur après utilisation
    reasonController.dispose();
    return result;
  }

  /// ✅ Dialogue d'activation
  Future<bool> _showActivationDialog(String agenceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activer l\'agence'),
        content: Text('Voulez-vous activer l\'agence "$agenceName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// 🔄 Effectuer le changement de statut
  Future<void> _performStatusChange(Map<String, dynamic> agence, bool newStatus, String? reason) async {
    try {
      final result = await AdminAgenceManagementService.toggleAgenceStatus(
        agenceId: agence['id'],
        newStatus: newStatus,
        reason: reason,
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadAgences();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAgenceCard(Map<String, dynamic> agence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getAgenceGradient(agence),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Icône d'agence
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Nom et code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agence['nom'] ?? 'Nom non défini',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Code: ${agence['code'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badges de statut
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatutDisplay(agence),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (agence['hasAdminAgence'] == true) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '👨‍💼 ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Informations principales
                _buildInfoRow(Icons.location_on_rounded, 'Adresse', agence['adresse'] ?? 'Non définie'),
                _buildInfoRow(Icons.map_rounded, 'Gouvernorat', agence['gouvernorat'] ?? 'Non défini'),
                _buildInfoRow(Icons.phone_rounded, 'Téléphone', agence['telephone'] ?? 'Non défini'),
                _buildInfoRow(Icons.email_rounded, 'Email', agence['emailContact'] ?? 'Non défini'),

                const SizedBox(height: 16),

                // Admin agence si présent
                if (agence['hasAdminAgence'] == true && agence['adminAgence'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Admin Agence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${agence['adminAgence']['prenom']} ${agence['adminAgence']['nom']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          agence['adminAgence']['email'] ?? 'Email non défini',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Statistiques de l'agence
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat('Agents', agence['nombreAgents']?.toString() ?? '0'),
                    ),
                    Expanded(
                      child: _buildMiniStat('Constats', agence['nombreConstats']?.toString() ?? '0'),
                    ),
                    Expanded(
                      child: _buildMiniStat('Experts', agence['nombreExperts']?.toString() ?? '0'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Actions
                _buildActionButtons(agence),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> agence) {
    final hasAdmin = agence['hasAdminAgence'] == true;

    return Column(
      children: [
        // Première ligne : Détails et Modifier
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAgenceDetails(agence),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('Détails', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFF059669)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEditAgenceDialog(agence),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Deuxième ligne : Gestion Admin
        if (!hasAdmin) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _assignAdminToAgence(agence),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Affecter Admin', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _manageAdminAgence(agence),
                  icon: const Icon(Icons.manage_accounts_rounded, size: 16),
                  label: const Text('Gérer', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _resetAdminPassword(agence),
                  icon: const Icon(Icons.lock_reset_rounded, size: 16),
                  label: const Text('Reset MDP', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _removeAdminFromAgence(agence),
                  icon: const Icon(Icons.person_remove_rounded, size: 16),
                  label: const Text('Retirer', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),

        // Troisième ligne : Statut agence
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _toggleAgenceStatus(agence),
            icon: Icon(
              agence['isActive'] != false ? Icons.block_rounded : Icons.check_circle_rounded,
              size: 16,
            ),
            label: Text(
              agence['isActive'] != false ? 'Désactiver Agence' : 'Activer Agence',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: agence['isActive'] != false ? Colors.red : Colors.green,
              side: BorderSide(color: agence['isActive'] != false ? Colors.red : Colors.green),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  /// 📋 Feuille de gestion de l'admin agence
  Widget _buildAdminManagementSheet(Map<String, dynamic> agence) {
    final adminData = agence['adminAgence'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
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
                        '${adminData['prenom']} ${adminData['nom']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Admin de ${agence['nom']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Informations de l'admin
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.email_rounded, 'Email', adminData['email'] ?? 'Non défini'),
                _buildInfoRow(Icons.phone_rounded, 'Téléphone', adminData['telephone'] ?? 'Non défini'),
                _buildInfoRow(Icons.credit_card_rounded, 'CIN', adminData['cin'] ?? 'Non défini'),
                _buildInfoRow(Icons.calendar_today_rounded, 'Statut',
                    adminData['isActive'] == true ? 'Actif' : 'Inactif'),

                const SizedBox(height: 20),

                // Actions
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAdminDetails(adminData);
                        },
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Voir les détails complets'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _resetAdminPassword(agence);
                            },
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text('Reset MDP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _removeAdminFromAgence(agence);
                            },
                            icon: const Icon(Icons.person_remove_rounded),
                            label: const Text('Retirer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 👁️ Afficher les détails de l'admin
  void _showAdminDetails(Map<String, dynamic> adminData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${adminData['prenom']} ${adminData['nom']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', adminData['email']),
              _buildDetailRow('Téléphone', adminData['telephone']),
              _buildDetailRow('CIN', adminData['cin']),
              _buildDetailRow('Agence', adminData['agenceNom']),
              _buildDetailRow('Compagnie', adminData['compagnieNom']),
              _buildDetailRow('Statut', adminData['isActive'] == true ? 'Actif' : 'Inactif'),
              _buildDetailRow('Rôle', adminData['role']),
              if (adminData['createdAt'] != null)
                _buildDetailRow('Créé le', adminData['createdAt'].toDate().toString().split(' ')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Ouvrir l'écran de modification
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non défini',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔗 Afficher le dialogue d'affectation d'admin
  void _showAssignAdminDialog(Map<String, dynamic> agence) async {
    try {
      // Charger les admins disponibles
      final availableAdmins = await AdminAgenceManagementService.getAvailableAdminsAgence(
        compagnieId: widget.userData['compagnieId'],
      );

      if (!mounted) return;

      if (availableAdmins.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun admin agence disponible pour affectation'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Afficher le dialogue de sélection
      final selectedAdmin = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Affecter un Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sélectionnez un admin à affecter à l\'agence "${agence['nom']}" :'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 200,
                child: ListView.builder(
                  itemCount: availableAdmins.length,
                  itemBuilder: (context, index) {
                    final admin = availableAdmins[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text(
                          '${admin['prenom']?[0] ?? ''}${admin['nom']?[0] ?? ''}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      title: Text('${admin['prenom']} ${admin['nom']}'),
                      subtitle: Text(admin['email'] ?? 'Email non défini'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: admin['isActive'] == true
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          admin['isActive'] == true ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: admin['isActive'] == true ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => Navigator.pop(context, admin),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _createAdminForAgence(agence);
              },
              child: const Text('Créer Nouveau'),
            ),
          ],
        ),
      );

      if (selectedAdmin != null) {
        // Confirmer l'affectation
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmer l\'affectation'),
            content: Text(
              'Voulez-vous affecter ${selectedAdmin['prenom']} ${selectedAdmin['nom']} '
              'à l\'agence "${agence['nom']}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Affecter'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final result = await AdminAgenceManagementService.assignAdminToAgence(
            adminId: selectedAdmin['id'],
            agenceId: agence['id'],
            agenceNom: agence['nom'],
          );

          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${result['message']}'),
                backgroundColor: Colors.green,
              ),
            );
            await _loadAgences();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
