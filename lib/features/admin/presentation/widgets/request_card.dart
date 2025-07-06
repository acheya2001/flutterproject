import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';
import '../../models/professional_request_model_final.dart';

/// 📝 Widget carte pour afficher une demande professionnelle
class RequestCard extends StatelessWidget {
  final ProfessionalRequestModel request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const RequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernTheme.spacingM),
      decoration: ModernTheme.cardDecoration(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(ModernTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et statut
              _buildHeader(),
              
              const SizedBox(height: ModernTheme.spacingS),
              
              // Informations principales
              _buildMainInfo(),
              
              const SizedBox(height: ModernTheme.spacingS),
              
              // Informations secondaires
              _buildSecondaryInfo(),
              
              if (request.estEnAttente) ...[
                const SizedBox(height: ModernTheme.spacingM),
                // Boutons d'action
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🔝 En-tête avec nom et statut
  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar avec initiales
        CircleAvatar(
          radius: 24,
          backgroundColor: _getStatusColor().withValues(alpha: 0.1),
          child: Text(
            '${request.prenom[0]}${request.nom[0]}',
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        const SizedBox(width: ModernTheme.spacingM),
        
        // Nom et type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.nomComplet,
                style: ModernTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                request.typeCompteFormate,
                style: ModernTheme.bodySmall.copyWith(
                  color: ModernTheme.textLight,
                ),
              ),
            ],
          ),
        ),
        
        // Badge de statut
        _buildStatusBadge(),
      ],
    );
  }

  /// 📋 Informations principales
  Widget _buildMainInfo() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.email,
          label: 'Email',
          value: request.email,
        ),
        const SizedBox(height: ModernTheme.spacingXS),
        _buildInfoRow(
          icon: Icons.phone,
          label: 'Téléphone',
          value: request.telephone,
        ),
      ],
    );
  }

  /// 📋 Informations secondaires
  Widget _buildSecondaryInfo() {
    return Column(
      children: [
        if (request.compagnieAssurance.isNotEmpty)
          _buildInfoRow(
            icon: Icons.business,
            label: 'Compagnie',
            value: request.compagnieAssurance,
          ),
        if (request.agence.isNotEmpty) ...[
          const SizedBox(height: ModernTheme.spacingXS),
          _buildInfoRow(
            icon: Icons.store,
            label: 'Agence',
            value: request.agence,
          ),
        ],
        if (request.zoneIntervention != null && request.zoneIntervention!.isNotEmpty) ...[
          const SizedBox(height: ModernTheme.spacingXS),
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Zone',
            value: request.zoneIntervention!,
          ),
        ],
        const SizedBox(height: ModernTheme.spacingXS),
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Date de demande',
          value: _formatDate(request.envoyeLe),
        ),
      ],
    );
  }

  /// 📝 Ligne d'information
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ModernTheme.textLight,
        ),
        const SizedBox(width: ModernTheme.spacingS),
        Text(
          '$label: ',
          style: ModernTheme.bodySmall.copyWith(
            color: ModernTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: ModernTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  /// 🏷️ Badge de statut
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernTheme.spacingS,
        vertical: ModernTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 12,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 4),
          Text(
            request.statutFormate,
            style: ModernTheme.bodySmall.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Bouton Rejeter
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rejeter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ModernTheme.errorColor,
              side: const BorderSide(color: ModernTheme.errorColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        const SizedBox(width: ModernTheme.spacingM),
        
        // Bouton Approuver
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approuver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎨 Couleur du statut
  Color _getStatusColor() {
    switch (request.statut) {
      case 'en_attente':
        return ModernTheme.warningColor;
      case 'approuvee':
        return ModernTheme.successColor;
      case 'rejetee':
        return ModernTheme.errorColor;
      default:
        return ModernTheme.textLight;
    }
  }

  /// 🎯 Icône du statut
  IconData _getStatusIcon() {
    switch (request.statut) {
      case 'en_attente':
        return Icons.pending_actions;
      case 'approuvee':
        return Icons.check_circle;
      case 'rejetee':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// 📅 Formater la date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
