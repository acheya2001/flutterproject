import 'package:flutter/material.dart';
import '../../../services/agent_service.dart';
import 'create_contrat_screen.dart';
import 'contrat_details_screen.dart';

/// 📋 Écran de gestion des contrats
class ContratsScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final Map<String, dynamic> userData;

  const ContratsScreen({
    Key? key,
    required this.agentData,
    required this.userData,
  }) : super(key: key);

  @override
  State<ContratsScreen> createState() => _ContratsScreenState();
}

class _ContratsScreenState extends State<ContratsScreen> {
  List<Map<String, dynamic>> _contrats = [];
  List<Map<String, dynamic>> _filteredContrats = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, actif, expire, suspendu

  @override
  void initState() {
    super.initState();
    _loadContrats();
  }

  /// 📋 Charger les contrats
  Future<void> _loadContrats() async {
    setState(() => _isLoading = true);

    try {
      final contrats = await AgentService.getAgentContrats(widget.agentData['id']);
      setState(() {
        _contrats = contrats;
        _applyFilters();
      });
    } catch (e) {
      debugPrint('[CONTRATS] ❌ Erreur chargement contrats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Appliquer les filtres
  void _applyFilters() {
    _filteredContrats = _contrats.where((contrat) {
      // Filtre par recherche
      final matchesSearch = _searchQuery.isEmpty ||
          contrat['numeroContrat'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contrat['nomAssure'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contrat['prenomAssure'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtre par statut
      final matchesStatus = _statusFilter == 'all' ||
          (_statusFilter == 'actif' && contrat['statut'] == 'actif') ||
          (_statusFilter == 'expire' && contrat['statut'] == 'expire') ||
          (_statusFilter == 'suspendu' && contrat['statut'] == 'suspendu');

      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
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
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewContrat,
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau Contrat'),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Contrats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_contrats.length} contrat(s) créé(s)',
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
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF667EEA)),
          SizedBox(height: 20),
          Text(
            'Chargement des contrats...',
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
        
        // Liste des contrats
        Expanded(
          child: _filteredContrats.isEmpty ? _buildEmptyState() : _buildContratsList(),
        ),
      ],
    );
  }

  /// 🔍 Barre de recherche et filtres
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un contrat...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF667EEA)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filtres par statut
          Row(
            children: [
              const Text(
                'Statut:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tous', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Actifs', 'actif'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expirés', 'expire'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Suspendus', 'suspendu'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _applyFilters();
        });
      },
      selectedColor: const Color(0xFF667EEA).withOpacity(0.2),
      checkmarkColor: const Color(0xFF667EEA),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// 📋 Liste des contrats
  Widget _buildContratsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredContrats.length,
      itemBuilder: (context, index) {
        final contrat = _filteredContrats[index];
        return _buildContratCard(contrat);
      },
    );
  }

  /// 📄 Carte de contrat
  Widget _buildContratCard(Map<String, dynamic> contrat) {
    final statut = contrat['statut'] ?? 'actif';
    Color statutColor;
    
    switch (statut) {
      case 'actif':
        statutColor = Colors.green;
        break;
      case 'expire':
        statutColor = Colors.red;
        break;
      case 'suspendu':
        statutColor = Colors.orange;
        break;
      default:
        statutColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showContratDetails(contrat),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête du contrat
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contrat['numeroContrat'] ?? 'N° non défini',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${contrat['prenomAssure']} ${contrat['nomAssure']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statut.toUpperCase(),
                        style: TextStyle(
                          color: statutColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Informations du contrat
                Row(
                  children: [
                    Expanded(
                      child: _buildContratInfo(
                        'Type',
                        contrat['typeContrat'] ?? 'Non défini',
                        Icons.category_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildContratInfo(
                        'Prime',
                        '${contrat['montantPrime'] ?? 0} DT',
                        Icons.attach_money_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildContratInfo(
                        'Début',
                        _formatDate(contrat['dateDebut']),
                        Icons.calendar_today_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildContratInfo(
                        'Fin',
                        _formatDate(contrat['dateFin']),
                        Icons.event_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📝 Information du contrat
  Widget _buildContratInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all'
                ? 'Aucun contrat trouvé'
                : 'Aucun contrat créé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != 'all'
                ? 'Essayez de modifier vos critères de recherche'
                : 'Commencez par créer votre premier contrat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _statusFilter == 'all') ...[
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _createNewContrat,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer un Contrat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ➕ Créer un nouveau contrat
  void _createNewContrat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateContratScreen(
          agentData: widget.agentData,
        ),
      ),
    );

    if (result == true) {
      _loadContrats(); // Recharger la liste
    }
  }

  /// 👁️ Afficher les détails d'un contrat
  void _showContratDetails(Map<String, dynamic> contrat) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContratDetailsScreen(
          contratData: contrat,
          agentData: widget.agentData,
        ),
      ),
    );

    if (result == true) {
      _loadContrats(); // Recharger la liste si des modifications ont été faites
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return 'Non défini';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = date.toDate();
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Format invalide';
    }
  }
}
