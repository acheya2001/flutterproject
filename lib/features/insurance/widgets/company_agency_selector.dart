import 'package:flutter/material.dart';
import '../models/insurance_structure_model.dart';
import '../services/insurance_structure_service.dart';

/// 🏢 Widget de sélection Compagnie → Agence
class CompanyAgencySelector extends StatefulWidget {
  final String? selectedCompanyId;
  final String? selectedAgencyId;
  final Function(String? companyId, String? agencyId) onSelectionChanged;
  final bool isRequired;

  const CompanyAgencySelector({
    super.key,
    this.selectedCompanyId,
    this.selectedAgencyId,
    required this.onSelectionChanged,
    this.isRequired = true,
  });

  @override
  State<CompanyAgencySelector> createState() => _CompanyAgencySelectorState();
}

class _CompanyAgencySelectorState extends State<CompanyAgencySelector> {
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _agencies = [];
  
  String? _selectedCompanyId;
  String? _selectedAgencyId;
  
  bool _isLoadingCompanies = true;
  bool _isLoadingAgencies = false;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _selectedCompanyId = widget.selectedCompanyId;
    _selectedAgencyId = widget.selectedAgencyId;

    // Utiliser addPostFrameCallback pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanies();
    });
    });
  }

  Future<void> _loadCompanies() async {
    if (mounted) setState(() {
      _isLoadingCompanies = true;
    });

    try {
      print('🔄 Widget: Chargement des compagnies...');
      final companies = await InsuranceStructureService.getActiveCompanies();
      print('📦 Widget: Compagnies reçues: ${companies.length}');
      if (mounted) setState(() {
        _companies = companies;
        _isLoadingCompanies = false;
      });
      print('✅ Widget: État mis à jour - Compagnies: ${_companies.length}');

      // Si une compagnie est pré-sélectionnée, charger ses agences
      if (_selectedCompanyId != null) {
        _loadAgencies(_selectedCompanyId!);
      }
    } catch (e) {
      print('❌ Widget: Erreur chargement compagnies: $e');
      if (mounted) setState(() {
        _isLoadingCompanies = false;
      });
      _showError('Erreur lors du chargement des compagnies: $e');
    }
  }

  Future<void> _loadAgencies(String companyId) async {
    if (mounted) setState(() {
      _isLoadingAgencies = true;
      _agencies = [];
      _selectedAgencyId = null;
    });

    try {
      final agencies = await InsuranceStructureService.getAgenciesByCompany(companyId);
      if (mounted) setState(() {
        _agencies = agencies;
        _isLoadingAgencies = false;
      });

      // Si une agence était pré-sélectionnée et qu'elle existe toujours
      if (widget.selectedAgencyId != null &&
          agencies.any((a) => (a['agencyId'] ?? a['id']) == widget.selectedAgencyId)) {
        if (mounted) setState(() {
          _selectedAgencyId = widget.selectedAgencyId;
        });
      }

      widget.onSelectionChanged(_selectedCompanyId, _selectedAgencyId);
    } catch (e) {
      if (mounted) setState(() {
        _isLoadingAgencies = false;
      });
      _showError('Erreur lors du chargement des agences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélection de la compagnie
        _buildCompanySelector(),
        
        const SizedBox(height: 16),
        
        // Sélection de l'agence
        _buildAgencySelector(),
      ],
    );
  }

  Widget _buildCompanySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Compagnie d\'assurance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isLoadingCompanies
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Chargement des compagnies...'),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCompanyId,
                    hint: const Text('Sélectionnez une compagnie'),
                    isExpanded: true,
                    items: _companies.map((company) {
                      return DropdownMenuItem<String>(
                        value: company['companyId'] ?? company['id'],
                        child: Row(
                          children: [
                            if (company['logo'] != null) ...[
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(company['logo']),
                                backgroundColor: Colors.grey[200],
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    company['name'] ?? company['nom'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if ((company['code'] ?? '').isNotEmpty)
                                    Text(
                                      company['code'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      print('🏢 Compagnie sélectionnée - ID: $newValue');
                      if (mounted) setState(() {
                        _selectedCompanyId = newValue;
                        _selectedAgencyId = null;
                        _agencies = [];
                      });

                      if (newValue != null) {
                        _loadAgencies(newValue);
                      } else {
                        widget.onSelectionChanged(null, null);
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAgencySelector() {
    final isEnabled = _selectedCompanyId != null && !_isLoadingAgencies;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Agence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isEnabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isEnabled ? Colors.white : Colors.grey[50],
          ),
          child: _isLoadingAgencies
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Chargement des agences...'),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAgencyId,
                    hint: Text(
                      _selectedCompanyId == null
                          ? 'Sélectionnez d\'abord une compagnie'
                          : 'Sélectionnez une agence',
                      style: TextStyle(
                        color: _selectedCompanyId == null 
                            ? Colors.grey[400] 
                            : Colors.grey[600],
                      ),
                    ),
                    isExpanded: true,
                    items: isEnabled
                        ? _agencies.map((agency) {
                            return DropdownMenuItem<String>(
                              value: agency['agencyId'] ?? agency['id'],
                              child: _buildAgencyItem(agency),
                            );
                          }).toList()
                        : [],
                    onChanged: isEnabled
                        ? (String? newValue) {
                            if (mounted) setState(() {
                              _selectedAgencyId = newValue;
                            });
                            widget.onSelectionChanged(_selectedCompanyId, newValue);
                          }
                        : null,
                  ),
                ),
        ),
        
        // Affichage du nombre d'agences
        if (_selectedCompanyId != null && !_isLoadingAgencies)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_agencies.length} agence(s) disponible(s)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 🏪 Widget pour afficher une agence avec ses informations
  Widget _buildAgencyItem(Map<String, dynamic> agency) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  agency['name'] ?? agency['nom'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (agency['nombreAgents'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${agency['nombreAgents']} agent${agency['nombreAgents'] > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if ((agency['address'] ?? agency['adresse'] ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${agency['address'] ?? agency['adresse'] ?? ''}, ${agency['city'] ?? agency['ville'] ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

