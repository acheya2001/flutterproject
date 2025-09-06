import 'package:flutter/material.dart';
import '../models/conducteur_vehicle_model.dart';

/// 🛡️ Widget pour afficher le statut d'assurance d'un véhicule
class VehicleInsuranceStatusWidget extends StatelessWidget {
  final ConducteurVehicleModel vehicle;
  final VoidCallback? onTap;

  const VehicleInsuranceStatusWidget({
    Key? key,
    required this.vehicle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasValidInsurance = vehicle.hasValidInsurance;
    final activeContract = vehicle.activeContracts.isNotEmpty ? vehicle.activeContracts.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: hasValidInsurance
                ? [Colors.green.shade50, Colors.blue.shade50]
                : [Colors.orange.shade50, Colors.red.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValidInsurance ? Colors.green.shade200 : Colors.orange.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasValidInsurance ? Colors.green : Colors.orange).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec véhicule
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasValidInsurance ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: hasValidInsurance ? Colors.green.shade700 : Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.plate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(hasValidInsurance),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations d'assurance
            if (hasValidInsurance && activeContract != null)
              _buildInsuranceInfo(activeContract!)
            else
              _buildNoInsuranceInfo(),
          ],
        ),
      ),
    );
  }

  /// 🏷️ Badge de statut
  Widget _buildStatusBadge(bool hasValidInsurance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasValidInsurance ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasValidInsurance ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasValidInsurance ? Icons.verified_rounded : Icons.warning_rounded,
            color: hasValidInsurance ? Colors.green.shade700 : Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            hasValidInsurance ? 'Assuré' : 'Non assuré',
            style: TextStyle(
              color: hasValidInsurance ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Informations d'assurance active
  Widget _buildInsuranceInfo(VehicleContract contract) {
    final daysUntilExpiry = contract.endDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysUntilExpiry <= 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Assurance Active',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Détails du contrat
          _buildInfoRow('N° Contrat', contract.contractNumber),
          _buildInfoRow('Compagnie', contract.companyName),
          _buildInfoRow('Type', _getContractTypeDisplay(contract.policyType ?? 'responsabilite_civile')),
          
          const SizedBox(height: 8),
          
          // Validité avec alerte si expiration proche
          Row(
            children: [
              Icon(
                isExpiringSoon ? Icons.warning_rounded : Icons.calendar_today_rounded,
                color: isExpiringSoon ? Colors.orange.shade600 : Colors.grey.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Valide jusqu\'au ${_formatDate(contract.endDate)}',
                style: TextStyle(
                  color: isExpiringSoon ? Colors.orange.shade700 : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          
          if (isExpiringSoon) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_rounded,
                    color: Colors.orange.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre assurance expire dans $daysUntilExpiry jour${daysUntilExpiry > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ❌ Informations pour véhicule non assuré
  Widget _buildNoInsuranceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Véhicule non assuré',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Ce véhicule n\'a pas d\'assurance active. Contactez votre agence pour souscrire une assurance.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Souscrire une assurance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// 🏷️ Affichage du type de contrat
  String _getContractTypeDisplay(String contractType) {
    switch (contractType) {
      case 'responsabilite_civile':
        return 'Responsabilité Civile';
      case 'tous_risques':
        return 'Tous Risques';
      case 'tiers_complet':
        return 'Tiers Complet';
      case 'vol_incendie':
        return 'Vol + Incendie';
      default:
        return contractType;
    }
  }
}
