import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// 🎯 Widget de filtres pour les demandes professionnelles
class RequestFilters extends StatelessWidget {
  final String selectedFilter;
  final String selectedType;
  final Function(String) onFilterChanged;
  final Function(String) onTypeChanged;

  const RequestFilters({
    super.key,
    required this.selectedFilter,
    required this.selectedType,
    required this.onFilterChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernTheme.spacingM,
        vertical: ModernTheme.spacingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtres par statut
          _buildFilterSection(
            title: 'Statut',
            filters: _statusFilters,
            selectedValue: selectedFilter,
            onChanged: onFilterChanged,
          ),
          
          const SizedBox(height: ModernTheme.spacingS),
          
          // Filtres par type
          _buildFilterSection(
            title: 'Type de compte',
            filters: _typeFilters,
            selectedValue: selectedType,
            onChanged: onTypeChanged,
          ),
        ],
      ),
    );
  }

  /// 📋 Section de filtres
  Widget _buildFilterSection({
    required String title,
    required List<FilterOption> filters,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ModernTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: ModernTheme.textDark,
          ),
        ),
        const SizedBox(height: ModernTheme.spacingXS),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final isSelected = selectedValue == filter.value;
              return Container(
                margin: const EdgeInsets.only(right: ModernTheme.spacingS),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (_) => onChanged(filter.value),
                  backgroundColor: Colors.white,
                  selectedColor: ModernTheme.primaryColor.withValues(alpha: 0.1),
                  checkmarkColor: ModernTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? ModernTheme.primaryColor : ModernTheme.textDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  side: BorderSide(
                    color: isSelected ? ModernTheme.primaryColor : ModernTheme.borderColor,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 📊 Options de filtre par statut
  static const List<FilterOption> _statusFilters = [
    FilterOption(value: 'tous', label: 'Tous'),
    FilterOption(value: 'en_attente', label: 'En attente'),
    FilterOption(value: 'approuvee', label: 'Approuvées'),
    FilterOption(value: 'rejetee', label: 'Rejetées'),
  ];

  /// 👥 Options de filtre par type
  static const List<FilterOption> _typeFilters = [
    FilterOption(value: 'tous', label: 'Tous'),
    FilterOption(value: 'agent', label: 'Agents'),
    FilterOption(value: 'expert', label: 'Experts'),
  ];
}

/// 🎯 Option de filtre
class FilterOption {
  final String value;
  final String label;

  const FilterOption({
    required this.value,
    required this.label,
  });
}

/// 🎯 Widget de filtre avancé (pour la boîte de dialogue)
class AdvancedFiltersDialog extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const AdvancedFiltersDialog({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<AdvancedFiltersDialog> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtres avancés'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtre par gouvernorat
            _buildDropdownFilter(
              label: 'Gouvernorat',
              value: _filters['gouvernorat'],
              items: _gouvernorats,
              onChanged: (value) {
                setState(() => _filters['gouvernorat'] = value);
              },
            ),
            
            const SizedBox(height: ModernTheme.spacingM),
            
            // Filtre par compagnie
            _buildDropdownFilter(
              label: 'Compagnie d\'assurance',
              value: _filters['compagnie'],
              items: _compagnies,
              onChanged: (value) {
                setState(() => _filters['compagnie'] = value);
              },
            ),
            
            const SizedBox(height: ModernTheme.spacingM),
            
            // Filtre par période
            _buildDateRangeFilter(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _filters.clear();
            });
          },
          child: const Text('Réinitialiser'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFiltersChanged(_filters);
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  /// 📋 Filtre dropdown
  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ModernTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ModernTheme.spacingXS),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spacingM,
              vertical: ModernTheme.spacingS,
            ),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous')),
            ...items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// 📅 Filtre par plage de dates
  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période de demande',
          style: ModernTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ModernTheme.spacingXS),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implémenter le sélecteur de date
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_filters['dateDebut'] ?? 'Date début'),
              ),
            ),
            const SizedBox(width: ModernTheme.spacingS),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implémenter le sélecteur de date
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_filters['dateFin'] ?? 'Date fin'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📍 Liste des gouvernorats
  static const List<String> _gouvernorats = [
    'Tunis', 'Ariana', 'Ben Arous', 'Manouba',
    'Nabeul', 'Zaghouan', 'Bizerte',
    'Béja', 'Jendouba', 'Kef', 'Siliana',
    'Sousse', 'Monastir', 'Mahdia', 'Sfax',
    'Kairouan', 'Kasserine', 'Sidi Bouzid',
    'Gabès', 'Medenine', 'Tataouine',
    'Gafsa', 'Tozeur', 'Kebili'
  ];

  /// 🏢 Liste des compagnies
  static const List<String> _compagnies = [
    'STAR Assurances',
    'Maghrebia Assurances',
    'Assurances Salim',
    'GAT Assurances',
    'Comar Assurances',
    'Lloyd Tunisien',
    'Zitouna Takaful',
    'Attijari Assurance',
  ];
}
