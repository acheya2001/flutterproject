import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 📅 Widget pour sélectionner une date avec un calendrier visuel
class DatePickerField extends StatefulWidget {
  final String label;
  final String? hintText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Function(DateTime?) onDateSelected;
  final bool isRequired;
  final IconData icon;
  final String? Function(String?)? validator;

  const DatePickerField({
    super.key,
    required this.label,
    this.hintText,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
    this.isRequired = false,
    this.icon = Icons.calendar_today,
    this.validator,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  DateTime? _selectedDate;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      widget.onDateSelected(picked);
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _controller.clear();
    });
    widget.onDateSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(widget.icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
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

        // Champ de date
        TextFormField(
          controller: _controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Sélectionnez une date',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(widget.icon),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearDate,
                    tooltip: 'Effacer la date',
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.blue),
                  onPressed: _selectDate,
                  tooltip: 'Sélectionner une date',
                ),
              ],
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: widget.validator,
          onTap: _selectDate,
        ),

        // Affichage de la date sélectionnée
        if (_selectedDate != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatDateWithDay(_selectedDate!),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateWithDay(DateTime date) {
    final dayNames = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    final monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    
    final dayName = dayNames[date.weekday - 1];
    final monthName = monthNames[date.month - 1];
    
    return '$dayName ${date.day} $monthName ${date.year}';
  }
}

/// 📅 Widget pour sélectionner une date avec validation automatique
class ValidatedDatePickerField extends StatelessWidget {
  final String label;
  final String? hintText;
  final DateTime? initialDate;
  final Function(DateTime?) onDateSelected;
  final bool isRequired;
  final IconData icon;
  final bool isPastDate;
  final bool isFutureDate;

  const ValidatedDatePickerField({
    super.key,
    required this.label,
    this.hintText,
    this.initialDate,
    required this.onDateSelected,
    this.isRequired = false,
    this.icon = Icons.calendar_today,
    this.isPastDate = false,
    this.isFutureDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return DatePickerField(
      label: label,
      hintText: hintText,
      initialDate: initialDate,
      firstDate: isPastDate ? DateTime(1900) : DateTime.now(),
      lastDate: isFutureDate ? DateTime(2100) : DateTime.now(),
      onDateSelected: onDateSelected,
      isRequired: isRequired,
      icon: icon,
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Cette date est obligatoire';
        }
        return null;
      },
    );
  }
}

/// 📅 Widget pour sélectionner une plage de dates
class DateRangePickerField extends StatefulWidget {
  final String label;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?, DateTime?) onDatesSelected;
  final bool isRequired;

  const DateRangePickerField({
    super.key,
    required this.label,
    this.startDate,
    this.endDate,
    required this.onDatesSelected,
    this.isRequired = false,
  });

  @override
  State<DateRangePickerField> createState() => _DateRangePickerFieldState();
}

class _DateRangePickerFieldState extends State<DateRangePickerField> {
  DateTimeRange? _selectedRange;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.startDate != null && widget.endDate != null) {
      _selectedRange = DateTimeRange(
        start: widget.startDate!,
        end: widget.endDate!,
      );
      _updateController();
    }
  }

  void _updateController() {
    if (_selectedRange != null) {
      final start = DateFormat('dd/MM/yyyy').format(_selectedRange!.start);
      final end = DateFormat('dd/MM/yyyy').format(_selectedRange!.end);
      _controller.text = '$start - $end';
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _updateController();
      });
      widget.onDatesSelected(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.date_range, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Sélectionnez une période',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.date_range),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
          ),
          onTap: _selectDateRange,
        ),
      ],
    );
  }
}
