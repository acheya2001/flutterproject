import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final String? Function(DateTime?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? hint;

  const CustomDatePicker({
    Key? key,
    required this.label,
    this.selectedDate,
    required this.onDateSelected,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.hint,
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = selectedDate ?? now;
    final DateTime firstPickerDate = firstDate ?? DateTime(now.year - 5);
    final DateTime lastPickerDate = lastDate ?? DateTime(now.year + 5);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstPickerDate,
      lastDate: lastPickerDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final displayText = selectedDate != null
        ? dateFormat.format(selectedDate!)
        : hint ?? 'Sélectionner une date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        FormField<DateTime>(
          initialValue: selectedDate,
          validator: validator,
          builder: (FormFieldState<DateTime> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: state.hasError
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: selectedDate != null
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}