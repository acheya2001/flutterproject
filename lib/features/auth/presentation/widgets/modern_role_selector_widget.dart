import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// 🎯 Widget moderne de sélection de rôle professionnel
class ModernRoleSelectorWidget extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const ModernRoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRoleCard(
          role: 'agent_agence',
          title: 'Agent d\'Agence',
          subtitle: 'Gérer les contrats et clients d\'une agence',
          icon: Icons.business_center,
          gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
          description: 'Vous travaillez dans une agence d\'assurance et gérez les contrats, les clients et les sinistres.',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: 'expert_auto',
          title: 'Expert Automobile',
          subtitle: 'Expertise et évaluation des sinistres',
          icon: Icons.car_repair,
          gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          description: 'Vous êtes expert automobile et réalisez des expertises pour les compagnies d\'assurance.',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: 'admin_compagnie',
          title: 'Admin Compagnie',
          subtitle: 'Administration d\'une compagnie d\'assurance',
          icon: Icons.corporate_fare,
          gradient: const [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          description: 'Vous administrez une compagnie d\'assurance et supervisez les opérations.',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: 'admin_agence',
          title: 'Admin Agence',
          subtitle: 'Administration d\'une agence d\'assurance',
          icon: Icons.store,
          gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          description: 'Vous dirigez une agence d\'assurance et gérez les équipes et les activités.',
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required String description,
  }) {
    final isSelected = selectedRole == role;
    
    return GestureDetector(
      onTap: () => onRoleSelected(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? gradient.first
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? gradient.first.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 15 : 8,
              offset: const Offset(0, 4),
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icône avec gradient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Titre et sous-titre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ModernTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: ModernTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de sélection
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? gradient.first : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? gradient.first : Colors.grey.shade300,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
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
            
            const SizedBox(height: 16),
            
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? gradient.first.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(
                  color: gradient.first.withValues(alpha: 0.2),
                  width: 1,
                ) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isSelected ? gradient.first : ModernTheme.textLight,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? gradient.first : ModernTheme.textLight,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge "Sélectionné"
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Sélectionné',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
