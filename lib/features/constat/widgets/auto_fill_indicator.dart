import 'package:flutter/material.dart';
import '../services/auto_fill_service.dart';

/// Widget qui affiche un indicateur des données pré-remplies automatiquement
class AutoFillIndicator extends StatelessWidget {
  final AutoFillData autoFillData;
  final VoidCallback? onRefresh;

  const AutoFillIndicator({
    Key? key,
    required this.autoFillData,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_fix_high,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Formulaire pré-rempli automatiquement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.green),
                  onPressed: onRefresh,
                  tooltip: 'Actualiser les données',
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Indicateurs de données remplies
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (autoFillData.conducteurComplete)
                _buildDataChip(
                  icon: Icons.person,
                  label: 'Conducteur',
                  subtitle: '${autoFillData.conducteurNom} ${autoFillData.conducteurPrenom}',
                  color: Colors.blue,
                ),
              
              if (autoFillData.vehiculeComplete)
                _buildDataChip(
                  icon: Icons.directions_car,
                  label: 'Véhicule',
                  subtitle: '${autoFillData.vehiculeMarque} ${autoFillData.vehiculeModele}',
                  color: Colors.orange,
                ),
              
              if (autoFillData.assuranceComplete)
                _buildDataChip(
                  icon: Icons.security,
                  label: 'Assurance',
                  subtitle: autoFillData.assuranceCompagnie,
                  color: Colors.purple,
                ),
              
              if (autoFillData.permisNumero.isNotEmpty)
                _buildDataChip(
                  icon: Icons.credit_card,
                  label: 'Permis',
                  subtitle: autoFillData.permisNumero,
                  color: Colors.teal,
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Message informatif
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Vérifiez et modifiez les informations si nécessaire. '
                    'Vous pouvez toujours ajouter ou corriger des détails.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget simplifié pour afficher un résumé rapide
class AutoFillSummary extends StatelessWidget {
  final AutoFillData autoFillData;

  const AutoFillSummary({
    Key? key,
    required this.autoFillData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedSections = [
      if (autoFillData.conducteurComplete) 'Conducteur',
      if (autoFillData.vehiculeComplete) 'Véhicule',
      if (autoFillData.assuranceComplete) 'Assurance',
    ];

    if (completedSections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pré-rempli: ${completedSections.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
