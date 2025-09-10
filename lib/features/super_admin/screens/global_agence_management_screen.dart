import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🌍 Écran de gestion globale des agences pour Super Admin
class GlobalAgenceManagementScreen extends StatefulWidget {
  const GlobalAgenceManagementScreen({Key? key}) : super(key: key);

  @override
  State<GlobalAgenceManagementScreen> createState() => _GlobalAgenceManagementScreenState();
}

class _GlobalAgenceManagementScreenState extends State<GlobalAgenceManagementScreen> {
  List<Map<String, dynamic>> _agences = [];
  List<Map<String, dynamic>> _filteredAgences = [];
  Map<String, Map<String, dynamic>> _compagnies = {};
  bool _isLoading = true;
  
  // Contrôleurs de recherche et filtres
  final _searchController = TextEditingController();
  String _selectedCompagnie = 'Toutes';
  String _selectedStatut = 'Tous';
  String _selectedAdminStatus = 'Tous';
  String _selectedGouvernorat = 'Tous';
  String _selectedOrigin = 'Toutes';
  String _selectedSecurity = 'Toutes';

  List<String> _compagnieOptions = ['Toutes'];
  final List<String> _statutOptions = ['Tous', 'Occupé', 'Libre', 'Désactivé'];
  final List<String> _adminStatusOptions = ['Tous', 'Avec Admin', 'Sans Admin'];
  final List<String> _originOptions = ['Toutes', 'Admin Compagnie', 'Super Admin', 'Inconnue'];
  final List<String> _securityOptions = ['Toutes', 'Activité Suspecte', 'Associations Valides'];
  final List<String> _gouvernoratOptions = [
    'Tous', 'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
    'Bizerte', 'Béja', 'Jendouba', 'Kef', 'Siliana', 'Sousse', 'Monastir',
    'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid', 'Gabès',
    'Médenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kébili'
  ];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
    _searchController.addListener(_filterAgences);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📊 Charger toutes les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les compagnies
      await _loadCompagnies();
      
      // Charger les agences avec leurs admins
      await _loadAgences();
      
      _filterAgences();
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🏢 Charger les compagnies
  Future<void> _loadCompagnies() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('compagnies')
        .orderBy('nom')
        .get();

    _compagnies.clear();
    _compagnieOptions = ['Toutes'];
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      _compagnies[doc.id] = data;
      _compagnieOptions.add(data['nom'] ?? doc.id);
    }
  }

  /// 🏪 Charger les agences avec leurs admins et métadonnées de création
  Future<void> _loadAgences() async {
    final agencesSnapshot = await FirebaseFirestore.instance
        .collection('agences')
        .orderBy('createdAt', descending: true) // Trier par date de création (plus récent en premier)
        .get();

    _agences.clear();

    for (var doc in agencesSnapshot.docs) {
      final agenceData = doc.data();
      agenceData['id'] = doc.id;

      // Enrichir avec les données de la compagnie
      final compagnieId = agenceData['compagnieId'];
      if (compagnieId != null && _compagnies.containsKey(compagnieId)) {
        agenceData['compagnieData'] = _compagnies[compagnieId];
      }

      // 🔍 Charger les informations sur qui a créé l'agence
      await _enrichWithCreationInfo(agenceData);

      // Charger l'admin agence s'il existe
      if (agenceData['hasAdminAgence'] == true) {
        try {
          final adminSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin_agence')
              .where('agenceId', isEqualTo: doc.id)
              .limit(1)
              .get();

          if (adminSnapshot.docs.isNotEmpty) {
            final adminData = adminSnapshot.docs.first.data();
            adminData['id'] = adminSnapshot.docs.first.id;
            agenceData['adminAgence'] = adminData;

            // 🔍 Charger les informations sur qui a créé l'admin
            await _enrichAdminWithCreationInfo(adminData);
          }
        } catch (e) {
          debugPrint('Erreur chargement admin agence ${doc.id}: $e');
        }
      }

      // Compter les agents
      try {
        final agentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'agent')
            .where('agenceId', isEqualTo: doc.id)
            .get();

        agenceData['nombreAgentsActuels'] = agentsSnapshot.docs.length;
        agenceData['nombreAgentsActifs'] = agentsSnapshot.docs
            .where((doc) => doc.data()['isActive'] == true).length;
      } catch (e) {
        agenceData['nombreAgentsActuels'] = 0;
        agenceData['nombreAgentsActifs'] = 0;
      }

      // Compter les constats de l'agence
      try {
        final constatsSnapshot = await FirebaseFirestore.instance
            .collection('constats')
            .where('agenceId', isEqualTo: doc.id)
            .get();

        agenceData['nombreConstats'] = constatsSnapshot.docs.length;
      } catch (e) {
        agenceData['nombreConstats'] = 0;
      }

      _agences.add(agenceData);
    }
  }

  /// 🔍 Enrichir avec les informations de création de l'agence
  Future<void> _enrichWithCreationInfo(Map<String, dynamic> agenceData) async {
    try {
      final createdBy = agenceData['createdBy'];
      final origin = agenceData['origin'] ?? 'unknown';
      final compagnieId = agenceData['compagnieId'];

      agenceData['creationInfo'] = {
        'origin': origin,
        'createdBy': createdBy,
        'createdAt': agenceData['createdAt'],
        'compagnieId': compagnieId,
      };

      // Si créé par un admin compagnie, charger ses infos ET vérifier l'association
      if (origin == 'admin_compagnie' && createdBy != null && compagnieId != null) {
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: createdBy)
            .where('role', isEqualTo: 'admin_compagnie')
            .where('compagnieId', isEqualTo: compagnieId) // 🔒 Vérification association compagnie
            .limit(1)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          final adminData = adminSnapshot.docs.first.data();
          agenceData['creationInfo']['creatorData'] = {
            'nom': '${adminData['prenom']} ${adminData['nom']}',
            'email': adminData['email'],
            'compagnie': adminData['compagnieNom'],
            'compagnieId': adminData['compagnieId'],
            'isValidAssociation': adminData['compagnieId'] == compagnieId,
          };

          // 🚨 Marquer si l'association est suspecte
          if (adminData['compagnieId'] != compagnieId) {
            agenceData['creationInfo']['suspiciousActivity'] = true;
            agenceData['creationInfo']['warning'] = 'Admin créateur non associé à cette compagnie';
          }
        } else {
          // 🚨 Admin non trouvé ou non associé à la bonne compagnie
          agenceData['creationInfo']['suspiciousActivity'] = true;
          agenceData['creationInfo']['warning'] = 'Admin créateur introuvable ou non autorisé';
        }
      }
    } catch (e) {
      debugPrint('Erreur enrichissement création agence: $e');
    }
  }

  /// 🔍 Enrichir avec les informations de création de l'admin
  Future<void> _enrichAdminWithCreationInfo(Map<String, dynamic> adminData) async {
    try {
      final createdBy = adminData['createdBy'];
      final origin = adminData['origin'] ?? 'unknown';
      final adminCompagnieId = adminData['compagnieId'];

      adminData['creationInfo'] = {
        'origin': origin,
        'createdBy': createdBy,
        'createdAt': adminData['createdAt'],
        'compagnieId': adminCompagnieId,
      };

      // Si créé par un admin compagnie, charger ses infos ET vérifier l'association
      if (origin == 'auto_creation' && createdBy != null && adminCompagnieId != null) {
        final creatorSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: createdBy)
            .where('role', isEqualTo: 'admin_compagnie')
            .where('compagnieId', isEqualTo: adminCompagnieId) // 🔒 Vérification association
            .limit(1)
            .get();

        if (creatorSnapshot.docs.isNotEmpty) {
          final creatorData = creatorSnapshot.docs.first.data();
          adminData['creationInfo']['creatorData'] = {
            'nom': '${creatorData['prenom']} ${creatorData['nom']}',
            'email': creatorData['email'],
            'compagnie': creatorData['compagnieNom'],
            'compagnieId': creatorData['compagnieId'],
            'isValidAssociation': creatorData['compagnieId'] == adminCompagnieId,
          };

          // 🚨 Marquer si l'association est suspecte
          if (creatorData['compagnieId'] != adminCompagnieId) {
            adminData['creationInfo']['suspiciousActivity'] = true;
            adminData['creationInfo']['warning'] = 'Admin créateur de compagnie différente';
          }
        } else {
          // 🚨 Créateur non trouvé ou non associé à la bonne compagnie
          adminData['creationInfo']['suspiciousActivity'] = true;
          adminData['creationInfo']['warning'] = 'Créateur introuvable ou non autorisé';
        }
      }
    } catch (e) {
      debugPrint('Erreur enrichissement création admin: $e');
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
        final compagnieMatch = agence['compagnieNom']?.toLowerCase().contains(query) ?? false;
        
        final compagnieFilter = _selectedCompagnie == 'Toutes' || 
            agence['compagnieNom'] == _selectedCompagnie;
        
        final statutMatch = _selectedStatut == 'Tous' || 
            _getStatutDisplay(agence).toLowerCase() == _selectedStatut.toLowerCase();
        
        final gouvernoratMatch = _selectedGouvernorat == 'Tous' || 
            agence['gouvernorat']?.toString() == _selectedGouvernorat;
        
        final adminMatch = _selectedAdminStatus == 'Tous' ||
            (_selectedAdminStatus == 'Avec Admin' && agence['hasAdminAgence'] == true) ||
            (_selectedAdminStatus == 'Sans Admin' && agence['hasAdminAgence'] != true);

        final originMatch = _selectedOrigin == 'Toutes' ||
            (_selectedOrigin == 'Admin Compagnie' && agence['creationInfo']?['origin'] == 'admin_compagnie') ||
            (_selectedOrigin == 'Super Admin' && agence['creationInfo']?['origin'] == 'super_admin') ||
            (_selectedOrigin == 'Inconnue' && (agence['creationInfo']?['origin'] == null ||
                agence['creationInfo']['origin'] == 'unknown'));

        final securityMatch = _selectedSecurity == 'Toutes' ||
            (_selectedSecurity == 'Activité Suspecte' && agence['creationInfo']?['suspiciousActivity'] == true) ||
            (_selectedSecurity == 'Associations Valides' && agence['creationInfo']?['suspiciousActivity'] != true);

        return (nomMatch || adresseMatch || codeMatch || compagnieMatch) &&
               compagnieFilter && statutMatch && gouvernoratMatch && adminMatch && originMatch && securityMatch;
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
      title: const Text(
        'Gestion Globale des Agences',
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
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Actualiser',
        ),
        IconButton(
          onPressed: () => _showGlobalStats(),
          icon: const Icon(Icons.analytics_rounded, color: Colors.white),
          tooltip: 'Statistiques Globales',
        ),
        IconButton(
          onPressed: () => _exportData(),
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          tooltip: 'Exporter',
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
            'Synchronisation des données...',
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

        // Statistiques par origine
        const SizedBox(height: 16),
        _buildOriginStats(),

        // Liste des agences
        Expanded(
          child: _filteredAgences.isEmpty
              ? _buildEmptyState()
              : _buildAgencesList(),
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, adresse, code ou compagnie...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF667EEA)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _filterAgences();
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtres en grille (3 colonnes pour inclure l'origine)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            children: [
              _buildFilterDropdown(
                'Compagnie',
                _selectedCompagnie,
                _compagnieOptions,
                (value) => setState(() {
                  _selectedCompagnie = value!;
                  _filterAgences();
                }),
              ),
              _buildFilterDropdown(
                'Statut',
                _selectedStatut,
                _statutOptions,
                (value) => setState(() {
                  _selectedStatut = value!;
                  _filterAgences();
                }),
              ),
              _buildFilterDropdown(
                'Admin',
                _selectedAdminStatus,
                _adminStatusOptions,
                (value) => setState(() {
                  _selectedAdminStatus = value!;
                  _filterAgences();
                }),
              ),
              _buildFilterDropdown(
                'Origine',
                _selectedOrigin,
                _originOptions,
                (value) => setState(() {
                  _selectedOrigin = value!;
                  _filterAgences();
                }),
              ),
              _buildFilterDropdown(
                'Gouvernorat',
                _selectedGouvernorat,
                _gouvernoratOptions,
                (value) => setState(() {
                  _selectedGouvernorat = value!;
                  _filterAgences();
                }),
              ),
              _buildFilterDropdown(
                'Sécurité',
                _selectedSecurity,
                _securityOptions,
                (value) => setState(() {
                  _selectedSecurity = value!;
                  _filterAgences();
                }),
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
    final totalAgents = _agences.fold<int>(0, (sum, a) => sum + (a['nombreAgentsActuels'] as int? ?? 0));
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Agences',
              totalAgences.toString(),
              Icons.business_rounded,
              const Color(0xFF667EEA),
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
              'Total Agents',
              totalAgents.toString(),
              Icons.people_rounded,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 🔽 Dropdown de filtre
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option, style: const TextStyle(fontSize: 12)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  /// 📋 Liste des agences
  Widget _buildAgencesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAgences.length,
      itemBuilder: (context, index) {
        final agence = _filteredAgences[index];
        return _buildGlobalAgenceCard(agence);
      },
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Aucune agence trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Modifiez vos critères de recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Obtenir le gradient de l'agence
  List<Color> _getAgenceGradient(Map<String, dynamic> agence) {
    final hasAdmin = agence['hasAdminAgence'] == true;
    final isActive = agence['isActive'] != false;

    if (!isActive) {
      return [Colors.grey.shade400, Colors.grey.shade600];
    } else if (hasAdmin) {
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    } else {
      return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    }
  }

  /// 📊 Obtenir l'affichage du statut
  String _getStatutDisplay(Map<String, dynamic> agence) {
    final isActive = agence['isActive'] != false;
    final hasAdmin = agence['hasAdminAgence'] == true;

    if (!isActive) return 'Désactivé';
    if (hasAdmin) return 'Occupé';
    return 'Libre';
  }

  /// 📊 Mini statistique
  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF667EEA),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information
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
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 Bouton d'action flottant
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateAgenceDialog(),
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_business_rounded),
      label: const Text('Nouvelle Agence'),
    );
  }

  /// 🏢 Carte d'agence globale
  Widget _buildGlobalAgenceCard(Map<String, dynamic> agence) {
    final hasAdmin = agence['hasAdminAgence'] == true;
    final adminData = agence['adminAgence'];
    final compagnieData = agence['compagnieData'];

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
          // En-tête avec compagnie et statut
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
            child: Column(
              children: [
                // Compagnie
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        agence['compagnieNom'] ?? 'Compagnie inconnue',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        compagnieData?['statut']?.toUpperCase() ?? 'INCONNU',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Agence
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store_rounded,
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
                        if (hasAdmin) ...[
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
              ],
            ),
          ),

          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Informations de l'agence
                _buildInfoRow(Icons.location_on_rounded, 'Adresse', agence['adresse'] ?? 'Non définie'),
                _buildInfoRow(Icons.map_rounded, 'Gouvernorat', agence['gouvernorat'] ?? 'Non défini'),
                _buildInfoRow(Icons.phone_rounded, 'Téléphone', agence['telephone'] ?? 'Non défini'),
                _buildInfoRow(Icons.email_rounded, 'Email', agence['emailContact'] ?? 'Non défini'),

                // Informations de création
                if (agence['creationInfo'] != null) ...[
                  const SizedBox(height: 12),
                  _buildCreationInfoSection(agence['creationInfo']),
                ],

                // 🚨 Alerte activité suspecte
                if (agence['creationInfo']?['suspiciousActivity'] == true) ...[
                  const SizedBox(height: 12),
                  _buildSuspiciousActivityAlert(agence['creationInfo']),
                ],

                const SizedBox(height: 16),

                // Admin agence si présent
                if (hasAdmin && adminData != null) ...[
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
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'Admin Agence',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            // Badge d'origine de création
                            if (adminData['creationInfo']?['origin'] == 'auto_creation')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Auto-créé',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${adminData['prenom']} ${adminData['nom']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          adminData['email'] ?? 'Email non défini',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Row(
                          children: [
                            Icon(
                              adminData['isActive'] == true ? Icons.check_circle : Icons.cancel,
                              color: adminData['isActive'] == true ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              adminData['isActive'] == true ? 'Actif' : 'Inactif',
                              style: TextStyle(
                                color: adminData['isActive'] == true ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Informations de création de l'admin
                        if (adminData['creationInfo']?['creatorData'] != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 12, color: Colors.blue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Créé par: ${adminData['creationInfo']['creatorData']['nom']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Statistiques de l'agence
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat('Agents', agence['nombreAgentsActuels']?.toString() ?? '0'),
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

                // Actions Super Admin
                _buildSuperAdminActions(agence),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions Super Admin
  Widget _buildSuperAdminActions(Map<String, dynamic> agence) {
    final hasAdmin = agence['hasAdminAgence'] == true;

    return Column(
      children: [
        // Première ligne : Actions principales
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAgenceDetails(agence),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('Détails', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF667EEA),
                  side: const BorderSide(color: Color(0xFF667EEA)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _editAgence(agence),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
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
              onPressed: () => _createAdminForAgence(agence),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Créer Admin Agence', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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
                  label: const Text('Gérer Admin', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleAdminStatus(agence),
                  icon: Icon(
                    agence['adminAgence']?['isActive'] == true
                        ? Icons.block_rounded
                        : Icons.check_circle_rounded,
                    size: 16,
                  ),
                  label: Text(
                    agence['adminAgence']?['isActive'] == true ? 'Désactiver' : 'Activer',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: agence['adminAgence']?['isActive'] == true
                        ? Colors.red
                        : Colors.green,
                    side: BorderSide(
                      color: agence['adminAgence']?['isActive'] == true
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),

        // Troisième ligne : Actions agence
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _toggleAgenceStatus(agence),
                icon: Icon(
                  agence['isActive'] != false ? Icons.block_rounded : Icons.check_circle_rounded,
                  size: 16,
                ),
                label: Text(
                  agence['isActive'] != false ? 'Désactiver' : 'Activer',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: agence['isActive'] != false ? Colors.red : Colors.green,
                  side: BorderSide(
                    color: agence['isActive'] != false ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deleteAgence(agence),
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('Supprimer', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Méthodes d'action
  void _showGlobalStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Statistiques Globales'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Agences', _agences.length.toString()),
              _buildStatRow('Avec Admin', _agences.where((a) => a['hasAdminAgence'] == true).length.toString()),
              _buildStatRow('Sans Admin', _agences.where((a) => a['hasAdminAgence'] != true).length.toString()),
              _buildStatRow('Actives', _agences.where((a) => a['isActive'] != false).length.toString()),
              _buildStatRow('Inactives', _agences.where((a) => a['isActive'] == false).length.toString()),
              _buildStatRow('Total Agents', _agences.fold<int>(0, (sum, a) => sum + (a['nombreAgentsActuels'] as int? ?? 0)).toString()),
              _buildStatRow('Compagnies', _compagnies.length.toString()),
            ],
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Fonctionnalité d\'export en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showCreateAgenceDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Création d\'agence en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAgenceDetails(Map<String, dynamic> agence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(agence['nom'] ?? 'Agence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Code', agence['code']),
              _buildDetailRow('Compagnie', agence['compagnieNom']),
              _buildDetailRow('Adresse', agence['adresse']),
              _buildDetailRow('Gouvernorat', agence['gouvernorat']),
              _buildDetailRow('Téléphone', agence['telephone']),
              _buildDetailRow('Email', agence['emailContact']),
              _buildDetailRow('Statut', _getStatutDisplay(agence)),
              _buildDetailRow('Admin', agence['hasAdminAgence'] == true ? 'Oui' : 'Non'),
              if (agence['adminAgence'] != null)
                _buildDetailRow('Admin Nom', '${agence['adminAgence']['prenom']} ${agence['adminAgence']['nom']}'),
            ],
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

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Non défini'),
          ),
        ],
      ),
    );
  }

  void _editAgence(Map<String, dynamic> agence) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Modification d\'agence en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _createAdminForAgence(Map<String, dynamic> agence) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Création d\'admin agence en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _manageAdminAgence(Map<String, dynamic> agence) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Gestion admin agence en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _toggleAdminStatus(Map<String, dynamic> agence) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Changement statut admin en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _toggleAgenceStatus(Map<String, dynamic> agence) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Changement statut agence en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteAgence(Map<String, dynamic> agence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Supprimer l\'agence'),
        content: Text('Voulez-vous vraiment supprimer l\'agence "${agence['nom']}" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚧 Suppression d\'agence en cours de développement'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// 📋 Section d'informations de création
  Widget _buildCreationInfoSection(Map<String, dynamic> creationInfo) {
    final origin = creationInfo['origin'];
    final creatorData = creationInfo['creatorData'];
    final createdAt = creationInfo['createdAt'];

    Color bgColor;
    Color textColor;
    IconData icon;
    String title;

    switch (origin) {
      case 'admin_compagnie':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.business_rounded;
        title = 'Créée par Admin Compagnie';
        break;
      case 'super_admin':
        bgColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        icon = Icons.admin_panel_settings_rounded;
        title = 'Créée par Super Admin';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.help_rounded;
        title = 'Origine inconnue';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          if (creatorData != null) ...[
            const SizedBox(height: 6),
            Text(
              'Par: ${creatorData['nom']}',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Email: ${creatorData['email']}',
              style: TextStyle(
                fontSize: 10,
                color: textColor.withOpacity(0.8),
              ),
            ),
            if (creatorData['compagnie'] != null)
              Text(
                'Compagnie: ${creatorData['compagnie']}',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withOpacity(0.8),
                ),
              ),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Le: ${_formatDate(createdAt)}',
              style: TextStyle(
                fontSize: 10,
                color: textColor.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📅 Formater la date
  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Date inconnue';

      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Format de date invalide';
      }

      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Erreur format date';
    }
  }

  /// 📊 Statistiques avec filtres par origine
  Widget _buildOriginStats() {
    final adminCompagnieCreated = _agences.where((a) =>
        a['creationInfo']?['origin'] == 'admin_compagnie').length;
    final superAdminCreated = _agences.where((a) =>
        a['creationInfo']?['origin'] == 'super_admin').length;
    final autoCreatedAdmins = _agences.where((a) =>
        a['adminAgence']?['creationInfo']?['origin'] == 'auto_creation').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Répartition par Origine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOriginStatCard(
                  'Par Admin Compagnie',
                  adminCompagnieCreated.toString(),
                  Icons.business_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOriginStatCard(
                  'Par Super Admin',
                  superAdminCreated.toString(),
                  Icons.admin_panel_settings_rounded,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOriginStatCard(
                  'Admins Auto-créés',
                  autoCreatedAdmins.toString(),
                  Icons.auto_awesome_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Carte de statistique par origine
  Widget _buildOriginStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 🚨 Alerte pour activité suspecte
  Widget _buildSuspiciousActivityAlert(Map<String, dynamic> creationInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚨 Activité Suspecte Détectée',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  creationInfo['warning'] ?? 'Association non valide détectée',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSuspiciousActivityDetails(creationInfo),
            icon: const Icon(Icons.info_outline, color: Colors.red, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 📋 Afficher les détails de l'activité suspecte
  void _showSuspiciousActivityDetails(Map<String, dynamic> creationInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Activité Suspecte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⚠️ ${creationInfo['warning']}'),
            const SizedBox(height: 16),
            const Text(
              'Détails de l\'analyse :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• Origine : ${creationInfo['origin']}'),
            Text('• Créé par : ${creationInfo['createdBy']}'),
            if (creationInfo['compagnieId'] != null)
              Text('• Compagnie ID : ${creationInfo['compagnieId']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🔍 Recommandation : Vérifiez manuellement cette création et contactez l\'admin concerné si nécessaire.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Ajouter action de signalement
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }
}

