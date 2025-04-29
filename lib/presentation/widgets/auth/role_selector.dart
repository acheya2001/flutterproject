import 'package:flutter/material.dart';
import 'package:constat_tunisie/core/enums/user_role.dart';
import 'package:constat_tunisie/core/theme/app_theme.dart';

class RoleSelector extends StatefulWidget {
  final UserRole selectedRole;
  final Function(UserRole) onRoleChanged;

  const RoleSelector({
    super.key, // Utilisation de super.key
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Je suis un:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkColor, // Utilisation de la couleur ajoutée
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                role: UserRole.driver,
                icon: Icons.drive_eta,
                label: 'Conducteur',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleOption(
                role: UserRole.insurance,
                icon: Icons.security,
                label: 'Assurance',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleOption(
                role: UserRole.expert,
                icon: Icons.engineering,
                label: 'Expert',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required UserRole role,
    required IconData icon,
    required String label,
  }) {
    final isSelected = widget.selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        widget.onRoleChanged(role);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? role.color.withAlpha(30) : AppTheme.lightGreyColor.withAlpha(100), // Remplacé withOpacity par withAlpha
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? role.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? role.color : AppTheme.greyColor, // Utilisation de la couleur ajoutée
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.darkColor : AppTheme.greyColor, // Utilisation des couleurs ajoutées
              ),
            ),
          ],
        ),
      ),
    );
  }
}
