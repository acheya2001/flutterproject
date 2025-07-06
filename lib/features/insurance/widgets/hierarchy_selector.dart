import 'package:flutter/material.dart';
import '../services/insurance_hierarchy_service.dart';

/// 🏢 Widget de sélection hiérarchique des assurances
class HierarchySelector extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelectionChanged;
  final Map<String, dynamic>? initialSelection;

  const HierarchySelector({
    Key? key,
    required this.onSelectionChanged,
    this.initialSelection,
  }) : super(key: key);

  @override
  State<HierarchySelector> createState() => _HierarchySelectorState();
}

class _HierarchySelectorState extends State<HierarchySelector> {
  String? _selectedCompany;
  String? _selectedGouvernorat;
  String? _selectedAgence;
  String? _selectedAgent;

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _gouvernorats = [];
  List<Map<String, dynamic>> _agences = [];
  List<Map<String, dynamic>> _agents = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _initializeFromSelection();
  }

  void _initializeFromSelection() {
    if (widget.initialSelection != null) {
      _selectedCompany = widget.initialSelection!['companyId'];
      _selectedGouvernorat = widget.initialSelection!['gouvernoratId'];
      _selectedAgence = widget.initialSelection!['agenceId'];
      _selectedAgent = widget.initialSelection!['agentId'];
    }
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);
    try {
      final companies = await InsuranceHierarchyService.getCompanies();
      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur chargement compagnies: $e');
    }
  }

  Future<void> _loadGouvernorats(String companyId) async {
    setState(() => _isLoading = true);
    try {
      final gouvernorats = await InsuranceHierarchyService.getGouvernorats(companyId);
      setState(() {
        _gouvernorats = gouvernorats;
        _selectedGouvernorat = null;
        _selectedAgence = null;
        _selectedAgent = null;
        _agences.clear();
        _agents.clear();
        _isLoading = false;
      });
      _notifyChange();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur chargement gouvernorats: $e');
    }
  }

  Future<void> _loadAgences(String companyId, String gouvernoratId) async {
    setState(() => _isLoading = true);
    try {
      final agences = await InsuranceHierarchyService.getAgences(companyId, gouvernoratId);
      setState(() {
        _agences = agences;
        _selectedAgence = null;
        _selectedAgent = null;
        _agents.clear();
        _isLoading = false;
      });
      _notifyChange();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur chargement agences: $e');
    }
  }

  Future<void> _loadAgents(String companyId, String gouvernoratId, String agenceId) async {
    setState(() => _isLoading = true);
    try {
      final agents = await InsuranceHierarchyService.getAgents(companyId, gouvernoratId, agenceId);
      setState(() {
        _agents = agents;
        _selectedAgent = null;
        _isLoading = false;
      });
      _notifyChange();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur chargement agents: $e');
    }
  }

  void _notifyChange() {
    final selection = {
      'companyId': _selectedCompany,
      'gouvernoratId': _selectedGouvernorat,
      'agenceId': _selectedAgence,
      'agentId': _selectedAgent,
      'companyData': _companies.firstWhere(
        (c) => c['id'] == _selectedCompany,
        orElse: () => {},
      ),
      'gouvernoratData': _gouvernorats.firstWhere(
        (g) => g['id'] == _selectedGouvernorat,
        orElse: () => {},
      ),
      'agenceData': _agences.firstWhere(
        (a) => a['id'] == _selectedAgence,
        orElse: () => {},
      ),
      'agentData': _agents.firstWhere(
        (a) => a['id'] == _selectedAgent,
        orElse: () => {},
      ),
    };
    widget.onSelectionChanged(selection);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏢 Sélection Hiérarchique',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        if (_isLoading) const LinearProgressIndicator(),

        // Sélection Compagnie
        _buildDropdown(
          label: '🏢 Compagnie d\'Assurance',
          value: _selectedCompany,
          items: _companies,
          onChanged: (value) {
            setState(() => _selectedCompany = value);
            if (value != null) _loadGouvernorats(value);
          },
          displayField: 'nom',
        ),

        const SizedBox(height: 16),

        // Sélection Gouvernorat
        _buildDropdown(
          label: '🗺️ Gouvernorat',
          value: _selectedGouvernorat,
          items: _gouvernorats,
          onChanged: _selectedCompany == null ? null : (value) {
            setState(() => _selectedGouvernorat = value);
            if (value != null) _loadAgences(_selectedCompany!, value);
          },
          displayField: 'nom',
        ),

        const SizedBox(height: 16),

        // Sélection Agence
        _buildDropdown(
          label: '🏪 Agence',
          value: _selectedAgence,
          items: _agences,
          onChanged: _selectedGouvernorat == null ? null : (value) {
            setState(() => _selectedAgence = value);
            if (value != null) _loadAgents(_selectedCompany!, _selectedGouvernorat!, value);
          },
          displayField: 'nom',
        ),

        const SizedBox(height: 16),

        // Sélection Agent
        _buildDropdown(
          label: '👨‍💼 Agent',
          value: _selectedAgent,
          items: _agents,
          onChanged: _selectedAgence == null ? null : (value) {
            setState(() => _selectedAgent = value);
            _notifyChange();
          },
          displayField: 'prenom',
          secondaryField: 'nom',
        ),

        const SizedBox(height: 16),

        // Résumé de la sélection
        if (_selectedCompany != null) _buildSelectionSummary(),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?)? onChanged,
    required String displayField,
    String? secondaryField,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((item) {
            final displayText = secondaryField != null
                ? '${item[displayField]} ${item[secondaryField]}'
                : item[displayField];
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(displayText),
            );
          }).toList(),
          hint: Text('Sélectionner ${label.toLowerCase()}'),
        ),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    final companyData = _companies.firstWhere(
      (c) => c['id'] == _selectedCompany,
      orElse: () => {},
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Résumé de la Sélection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (companyData.isNotEmpty)
            Text('🏢 ${companyData['nom']}'),
          if (_selectedGouvernorat != null)
            Text('🗺️ $_selectedGouvernorat'),
          if (_selectedAgence != null) ...[
            const SizedBox(height: 4),
            Text('🏪 ${_agences.firstWhere((a) => a['id'] == _selectedAgence, orElse: () => {})['nom'] ?? ''}'),
          ],
          if (_selectedAgent != null) ...[
            const SizedBox(height: 4),
            Text('👨‍💼 ${_agents.firstWhere((a) => a['id'] == _selectedAgent, orElse: () => {})['prenom'] ?? ''} ${_agents.firstWhere((a) => a['id'] == _selectedAgent, orElse: () => {})['nom'] ?? ''}'),
          ],
        ],
      ),
    );
  }
}
