import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// 🎯 Widget de sélection de rôle professionnel
class RoleSelectorWidget extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _roles.map((role) {
        final isSelected = selectedRole == role.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: ModernTheme.spacingM),
          child: InkWell(
            onTap: () => onRoleSelected(role.value),
            borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(ModernTheme.spacingM),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ModernTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                border: Border.all(
                  color: isSelected 
                      ? ModernTheme.primaryColor
                      : ModernTheme.borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icône du rôle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? ModernTheme.primaryColor
                          : role.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                    ),
                    child: Icon(
                      role.icon,
                      color: isSelected ? Colors.white : role.color,
                      size: 28,
                    ),
                  ),
                  
                  const SizedBox(width: ModernTheme.spacingM),
                  
                  // Informations du rôle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: ModernTheme.headingSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? ModernTheme.primaryColor
                                : ModernTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.description,
                          style: ModernTheme.bodySmall.copyWith(
                            color: ModernTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: ModernTheme.spacingS),
                        
                        // Badges des responsabilités
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: role.responsibilities.map((responsibility) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: role.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                                border: Border.all(
                                  color: role.color.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                responsibility,
                                style: TextStyle(
                                  color: role.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Indicateur de sélection
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? ModernTheme.primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? ModernTheme.primaryColor
                            : ModernTheme.borderColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 📋 Liste des rôles disponibles
  static const List<RoleOption> _roles = [
    RoleOption(
      value: 'agent_agence',
      title: 'Agent d\'Agence',
      description: 'Gérer les contrats et accompagner les clients dans une agence d\'assurance',
      icon: Icons.person_outline,
      color: ModernTheme.primaryColor,
      responsibilities: [
        'Vente de contrats',
        'Service client',
        'Gestion sinistres',
        'Conseils assurance',
      ],
    ),
    RoleOption(
      value: 'expert_auto',
      title: 'Expert Automobile',
      description: 'Évaluer les dommages et estimer les coûts de réparation des véhicules',
      icon: Icons.engineering,
      color: ModernTheme.secondaryColor,
      responsibilities: [
        'Expertise véhicules',
        'Évaluation dommages',
        'Rapports techniques',
        'Estimation coûts',
      ],
    ),
    RoleOption(
      value: 'admin_compagnie',
      title: 'Admin Compagnie',
      description: 'Administrer et superviser les opérations d\'une compagnie d\'assurance',
      icon: Icons.business,
      color: ModernTheme.accentColor,
      responsibilities: [
        'Gestion compagnie',
        'Supervision agences',
        'Stratégie commerciale',
        'Contrôle qualité',
      ],
    ),
    RoleOption(
      value: 'admin_agence',
      title: 'Admin Agence',
      description: 'Diriger et coordonner les activités d\'une agence d\'assurance',
      icon: Icons.store,
      color: ModernTheme.warningColor,
      responsibilities: [
        'Direction agence',
        'Gestion équipe',
        'Performance commerciale',
        'Relations clients',
      ],
    ),
  ];
}

/// 🎯 Modèle d'option de rôle
class RoleOption {
  final String value;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> responsibilities;

  const RoleOption({
    required this.value,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.responsibilities,
  });
}

/// 🎯 Widget de carte de rôle compacte (pour usage dans d'autres écrans)
class CompactRoleCard extends StatelessWidget {
  final RoleOption role;
  final bool isSelected;
  final VoidCallback? onTap;

  const CompactRoleCard({
    super.key,
    required this.role,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(ModernTheme.spacingM),
        decoration: BoxDecoration(
          color: isSelected 
              ? role.color.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? role.color : ModernTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? role.color
                    : role.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              ),
              child: Icon(
                role.icon,
                color: isSelected ? Colors.white : role.color,
                size: 24,
              ),
            ),
            const SizedBox(height: ModernTheme.spacingS),
            Text(
              role.title,
              style: ModernTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? role.color : ModernTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              role.description,
              style: ModernTheme.bodySmall.copyWith(
                color: ModernTheme.textLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 Widget de sélection de rôle en grille (alternative)
class GridRoleSelector extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const GridRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: ModernTheme.spacingM,
        mainAxisSpacing: ModernTheme.spacingM,
        childAspectRatio: 0.8,
      ),
      itemCount: RoleSelectorWidget._roles.length,
      itemBuilder: (context, index) {
        final role = RoleSelectorWidget._roles[index];
        final isSelected = selectedRole == role.value;
        
        return CompactRoleCard(
          role: role,
          isSelected: isSelected,
          onTap: () => onRoleSelected(role.value),
        );
      },
    );
  }
}

/// 🎯 Widget de badge de rôle (pour affichage dans les listes)
class RoleBadge extends StatelessWidget {
  final String roleValue;
  final bool showIcon;

  const RoleBadge({
    super.key,
    required this.roleValue,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final role = RoleSelectorWidget._roles.firstWhere(
      (r) => r.value == roleValue,
      orElse: () => const RoleOption(
        value: '',
        title: 'Inconnu',
        description: '',
        icon: Icons.help,
        color: Colors.grey,
        responsibilities: [],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernTheme.spacingS,
        vertical: ModernTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: role.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: role.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              role.icon,
              color: role.color,
              size: 16,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            role.title,
            style: TextStyle(
              color: role.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
