import 'package:flutter/material.dart';
import '../../models/professional_request_model_final.dart';
import '../../../../core/theme/modern_theme.dart';

/// 📋 Widget pour afficher une demande de compte professionnel
class ProfessionalRequestCard extends StatelessWidget {
  final ProfessionalRequestModel request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;

  const ProfessionalRequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.nomComplet,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ModernTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.roleFormate,
                        style: TextStyle(
                          fontSize: 14,
                          color: ModernTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations principales
            _buildInfoRow(Icons.email, 'Email', request.email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Téléphone', request.tel),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.credit_card, 'CIN', request.cin),
            
            // Informations spécifiques selon le rôle
            if (request.roleDemande == 'agent_agence') ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.business, 'Agence', request.nomAgence ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.domain, 'Compagnie', request.compagnie ?? 'N/A'),
            ],
            
            if (request.roleDemande == 'expert_auto') ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.verified, 'N° Agrément', request.numAgrement ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Zone', request.zoneIntervention ?? 'N/A'),
            ],
            
            if (request.roleDemande == 'admin_compagnie') ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.corporate_fare, 'Compagnie', request.nomCompagnie ?? 'N/A'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.work, 'Fonction', request.fonction ?? 'N/A'),
            ],
            
            const SizedBox(height: 16),
            
            // Date de soumission
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: ModernTheme.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Soumis le ${_formatDate(request.envoyeLe)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ModernTheme.textLight,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            if (request.status == 'en_attente') _buildActionButtons(context),
            
            // Bouton voir détails moderne
            if (onViewDetails != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ModernTheme.primaryColor.withValues(alpha: 0.1),
                        ModernTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ModernTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onViewDetails,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 20,
                              color: ModernTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Voir les détails',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ModernTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 🏷️ Chip de statut
  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (request.status) {
      case 'en_attente':
        backgroundColor = ModernTheme.warningColor.withValues(alpha: 0.1);
        textColor = ModernTheme.warningColor;
        label = 'En attente';
        icon = Icons.pending;
        break;
      case 'acceptee':
        backgroundColor = ModernTheme.successColor.withValues(alpha: 0.1);
        textColor = ModernTheme.successColor;
        label = 'Approuvée';
        icon = Icons.check_circle;
        break;
      case 'rejetee':
        backgroundColor = ModernTheme.errorColor.withValues(alpha: 0.1);
        textColor = ModernTheme.errorColor;
        label = 'Rejetée';
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
        label = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ModernTheme.textLight,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: ModernTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: ModernTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 🎯 Boutons d'action pour les demandes en attente
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
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
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rejeter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// 📅 Formater la date
  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
