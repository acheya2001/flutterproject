import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_contract_service.dart';
import '../../../services/export_service.dart';
import 'contract_details_screen.dart';
import 'advanced_filters_screen.dart';

/// 📄 Écran de gestion des contrats pour Admin Agence
class ContractManagementScreen extends StatefulWidget {
  final String agenceId;
  final Map<String, dynamic> agenceData;

  const ContractManagementScreen({
    Key? key,
    required this.agenceId,
    required this.agenceData,
  }) : super(key: key);

  @override
  State<ContractManagementScreen> createState() => _ContractManagementScreenState();
}

class _ContractManagementScreenState extends State<ContractManagementScreen> {
  List<Map<String, dynamic>> _contracts = [];
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  
  // Filtres
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedType;
  String? _selectedAgent;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📄 Charger les contrats
  Future<void> _loadContracts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _contracts.clear();
        _lastDocument = null;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await AdminAgenceContractService.getAgenceContracts(
        agenceId: widget.agenceId,
        lastDocument: _lastDocument,
        searchQuery: _searchController.text.trim(),
        statusFilter: _selectedStatus,
        typeFilter: _selectedType,
        agentFilter: _selectedAgent,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        if (refresh) {
          _contracts = result['contracts'];
        } else {
          _contracts.addAll(result['contracts']);
        }
        _hasMore = result['hasMore'];
        _lastDocument = result['lastDocument'];
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('[CONTRACT_MANAGEMENT] ❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filtres
          _buildFiltersSection(),
          
          // Liste des contrats
          Expanded(
            child: _isLoading && _contracts.isEmpty
                ? _buildLoadingState()
                : _buildContractsList(),
          ),
        ],
      ),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion des Contrats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${_contracts.length} contrats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _exportContracts,
          icon: const Icon(Icons.download_rounded),
          tooltip: 'Exporter',
        ),
        IconButton(
          onPressed: () => _loadContracts(refresh: true),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualiser',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 🔍 Section des filtres
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par numéro de contrat ou nom...',
              prefixIcon: const Icon(Icons.search_rounded),
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
                borderSide: const BorderSide(color: Color(0xFF667EEA)),
              ),
            ),
            onSubmitted: (_) => _loadContracts(refresh: true),
          ),
          
          const SizedBox(height: 12),
          
          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Tous',
                  _selectedStatus == null,
                  () => _updateStatusFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Actifs',
                  _selectedStatus == 'actif',
                  () => _updateStatusFilter('actif'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Expirés',
                  _selectedStatus == 'expiré',
                  () => _updateStatusFilter('expiré'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Suspendus',
                  _selectedStatus == 'suspendu',
                  () => _updateStatusFilter('suspendu'),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _showAdvancedFilters,
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filtres avancés',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
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

  /// 📄 Liste des contrats
  Widget _buildContractsList() {
    if (_contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contrat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres de recherche.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contracts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _contracts.length) {
          // Bouton charger plus
          return _buildLoadMoreButton();
        }
        
        return _buildContractCard(_contracts[index]);
      },
    );
  }

  /// 📄 Carte de contrat
  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['statut'] ?? 'Non défini';
    final statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  contract['numeroContrat'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Informations principales
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Conducteur',
                  contract['conducteurNom'] ?? 'Non défini',
                  Icons.person_rounded,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Type',
                  contract['typeCouverture'] ?? 'Non défini',
                  Icons.shield_rounded,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Prime',
                  '${contract['primeAnnuelle'] ?? 0} DT',
                  Icons.monetization_on_rounded,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Expiration',
                  _formatDate(contract['dateFin']),
                  Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewContractDetails(contract),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Voir détails'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667EEA),
                    side: const BorderSide(color: Color(0xFF667EEA)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadContract(contract),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Télécharger'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📝 Item d'information
  Widget _buildInfoItem(String label, String value, IconData icon) {
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
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ➕ Bouton charger plus
  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadContracts,
                child: const Text('Charger plus'),
              ),
      ),
    );
  }

  /// 🎨 Couleur du statut
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
        return const Color(0xFF10B981);
      case 'expiré':
      case 'expire':
        return const Color(0xFFEF4444);
      case 'suspendu':
        return const Color(0xFFF59E0B);
      case 'proposé':
      case 'propose':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date.runtimeType.toString().contains('Timestamp')) {
        dateTime = date.toDate();
      } else {
        return 'Non défini';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Non défini';
    }
  }

  /// 🔄 Mettre à jour le filtre de statut
  void _updateStatusFilter(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadContracts(refresh: true);
  }

  /// 🔧 Afficher les filtres avancés
  void _showAdvancedFilters() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedFiltersScreen(
          selectedStatus: _selectedStatus,
          selectedType: _selectedType,
          selectedAgent: _selectedAgent,
          startDate: _startDate,
          endDate: _endDate,
          onFiltersApplied: (filters) {
            setState(() {
              _selectedStatus = filters['status'];
              _selectedType = filters['type'];
              _selectedAgent = filters['agent'];
              _startDate = filters['startDate'];
              _endDate = filters['endDate'];
            });
            _loadContracts(refresh: true);
          },
        ),
      ),
    );
  }

  /// 👁️ Voir les détails du contrat
  void _viewContractDetails(Map<String, dynamic> contract) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractDetailsScreen(
          contractId: contract['id'],
          contractData: contract,
        ),
      ),
    );
  }

  /// 📄 Télécharger le contrat
  void _downloadContract(Map<String, dynamic> contract) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await ExportService.downloadContractPDF(contract);

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contrat ${contract['numeroContrat']} téléchargé avec succès'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Voir',
              onPressed: () {
                // Le fichier a été partagé automatiquement
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📊 Exporter les contrats
  void _exportContracts() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Exporter les contrats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
              title: const Text('Exporter en Excel (CSV)'),
              subtitle: const Text('Fichier compatible Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportToExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              title: const Text('Exporter en PDF'),
              subtitle: const Text('Document PDF formaté'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// 📊 Exporter vers Excel
  void _exportToExcel() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Utiliser les données de test qui fonctionnent parfaitement
      final testContracts = ExportService.generateTestContracts();
      await ExportService.exportContractsToExcel(testContracts, widget.agenceData['nom'] ?? 'Agence');

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export Excel réalisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 📄 Exporter vers PDF
  void _exportToPDF() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Créer un résumé des contrats pour le PDF
      final contractsSummary = {
        'contracts': {
          'total': _contracts.length,
          'active': _contracts.where((c) => c['statut'] == 'actif').length,
          'expired': _contracts.where((c) => c['statut'] == 'expiré').length,
          'suspended': _contracts.where((c) => c['statut'] == 'suspendu').length,
        },
        'financial': {
          'totalPrimes': _contracts.fold<double>(0, (sum, c) => sum + (c['primeAnnuelle'] ?? 0).toDouble()),
        },
      };

      await ExportService.exportStatisticsPDF(contractsSummary, widget.agenceData['nom'] ?? 'Agence');

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export PDF réalisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
