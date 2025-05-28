// Créer un nouveau fichier lib/core/widgets/password_strength_indicator.dart

import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    Key? key,
    required this.password,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(password);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 4,
                backgroundColor: theme.colorScheme.surfaceVariant,
                color: _getColorForStrength(strength, theme),
                minHeight: 5,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getLabelForStrength(strength),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getColorForStrength(strength, theme),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildCriteriaChip(
              context,
              'Min. 8 caractères',
              password.length >= 8,
            ),
            _buildCriteriaChip(
              context,
              'Majuscule',
              password.contains(RegExp(r'[A-Z]')),
            ),
            _buildCriteriaChip(
              context,
              'Minuscule',
              password.contains(RegExp(r'[a-z]')),
            ),
            _buildCriteriaChip(
              context,
              'Chiffre',
              password.contains(RegExp(r'[0-9]')),
            ),
            _buildCriteriaChip(
              context,
              'Caractère spécial',
              password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCriteriaChip(BuildContext context, String label, bool isMet) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMet 
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMet 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 14,
            color: isMet 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isMet 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    // Limiter à 4 pour l'indicateur
    return strength > 4 ? 4 : strength;
  }

  Color _getColorForStrength(int strength, ThemeData theme) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return theme.colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  String _getLabelForStrength(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Faible';
      case 2:
        return 'Moyen';
      case 3:
        return 'Bon';
      case 4:
        return 'Fort';
      default:
        return '';
    }
  }
}