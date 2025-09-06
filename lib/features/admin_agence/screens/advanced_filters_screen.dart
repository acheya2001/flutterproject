import 'package:flutter/material.dart';

/// 🔧 Écran de filtres avancés pour les contrats
class AdvancedFiltersScreen extends StatefulWidget {
  final String? selectedStatus;
  final String? selectedType;
  final String? selectedAgent;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const AdvancedFiltersScreen({
    Key? key,
    this.selectedStatus,
    this.selectedType,
    this.selectedAgent,
    this.startDate,
    this.endDate,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  String? _selectedStatus;
  String? _selectedType;
  String? _selectedAgent;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final List<String> _statusOptions = ['actif', 'expiré', 'suspendu', 'proposé'];
  final List<String> _typeOptions = ['RC Obligatoire', 'Tous Risques', 'Vol & Incendie', 'Dommages Collision'];
  final List<String> _agentOptions = ['Agent 1', 'Agent 2', 'Agent 3']; // TODO: Récupérer depuis Firestore

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedType = widget.selectedType;
    _selectedAgent = widget.selectedAgent;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Filtres Avancés',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetFilters,
          child: const Text(
            'Réinitialiser',
            style: TextStyle(
              color: Color(0xFF667EEA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 📄 Contenu principal
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          _buildFilterSection(
            'Statut du contrat',
            Icons.info_rounded,
            _buildStatusFilter(),
          ),
          const SizedBox(height: 24),

          // Type de couverture
          _buildFilterSection(
            'Type de couverture',
            Icons.shield_rounded,
            _buildTypeFilter(),
          ),
          const SizedBox(height: 24),

          // Agent
          _buildFilterSection(
            'Agent responsable',
            Icons.person_rounded,
            _buildAgentFilter(),
          ),
          const SizedBox(height: 24),

          // Période
          _buildFilterSection(
            'Période',
            Icons.date_range_rounded,
            _buildDateFilter(),
          ),
        ],
      ),
    );
  }

  /// 📋 Section de filtre
  Widget _buildFilterSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(icon, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  /// 📊 Filtre de statut
  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          'Tous',
          _selectedStatus == null,
          () => setState(() => _selectedStatus = null),
        ),
        ..._statusOptions.map((status) => _buildFilterChip(
          status.toUpperCase(),
          _selectedStatus == status,
          () => setState(() => _selectedStatus = status),
        )).toList(),
      ],
    );
  }

  /// 🛡️ Filtre de type
  Widget _buildTypeFilter() {
    return Column(
      children: [
        _buildDropdownField(
          'Type de couverture',
          _selectedType,
          ['Tous', ..._typeOptions],
          (value) => setState(() => _selectedType = value == 'Tous' ? null : value),
        ),
      ],
    );
  }

  /// 👤 Filtre d'agent
  Widget _buildAgentFilter() {
    return Column(
      children: [
        _buildDropdownField(
          'Agent responsable',
          _selectedAgent,
          ['Tous', ..._agentOptions],
          (value) => setState(() => _selectedAgent = value == 'Tous' ? null : value),
        ),
      ],
    );
  }

  /// 📅 Filtre de date
  Widget _buildDateFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Date de début',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                'Date de fin',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _setThisMonth,
                child: const Text('Ce mois'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _setLastMonth,
                child: const Text('Mois dernier'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _setThisYear,
                child: const Text('Cette année'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 📋 Champ dropdown
  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
      onChanged: onChanged,
    );
  }

  /// 📅 Champ de date
  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: value != null ? _formatDate(value) : 'Sélectionner',
        suffixIcon: const Icon(Icons.calendar_today_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
    );
  }

  /// 📱 Barre du bas
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF667EEA)),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Color(0xFF667EEA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Appliquer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Réinitialiser les filtres
  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedType = null;
      _selectedAgent = null;
      _startDate = null;
      _endDate = null;
    });
  }

  /// ✅ Appliquer les filtres
  void _applyFilters() {
    widget.onFiltersApplied({
      'status': _selectedStatus,
      'type': _selectedType,
      'agent': _selectedAgent,
      'startDate': _startDate,
      'endDate': _endDate,
    });
    Navigator.pop(context);
  }

  /// 📅 Définir ce mois
  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  /// 📅 Définir le mois dernier
  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0);
    });
  }

  /// 📅 Définir cette année
  void _setThisYear() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, 12, 31);
    });
  }

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
