import 'package:flutter/material.dart';
import '../models/vehicule_assure_model.dart';

/// 🚗 Widget de carte véhicule
class VehicleCard extends StatelessWidget {
  final VehiculeAssureModel vehicule;
  final VoidCallback? onTap;
  final bool showOwnerInfo;
  final bool showContractInfo;
  final Color? accentColor;

  const VehicleCard({
    super.key,
    required this.vehicule,
    this.onTap,
    this.showOwnerInfo = false,
    this.showContractInfo = true,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? Colors.blue;
    final bool isAssure = vehicule.isAssure;
    final bool expireBientot = vehicule.contrat.expireBientot;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête véhicule
              _buildVehicleHeader(accent, isAssure, expireBientot),
              
              const SizedBox(height: 12),
              
              // Informations véhicule
              _buildVehicleInfo(),
              
              if (showOwnerInfo) ...[
                const SizedBox(height: 12),
                _buildOwnerInfo(),
              ],
              
              if (showContractInfo) ...[
                const SizedBox(height: 12),
                _buildContractInfo(isAssure, expireBientot),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleHeader(Color accent, bool isAssure, bool expireBientot) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!isAssure) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'Expiré';
    } else if (expireBientot) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'Expire bientôt';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Assuré';
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.directions_car, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicule.descriptionVehicule,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                vehicule.vehicule.immatriculation,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.palette,
                  'Couleur',
                  vehicule.vehicule.couleur,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.calendar_today,
                  'Année',
                  vehicule.vehicule.annee.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.local_gas_station,
                  'Carburant',
                  vehicule.vehicule.typeCarburant,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.speed,
                  'Puissance',
                  '${vehicule.vehicule.puissanceFiscale} CV',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Propriétaire',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vehicule.proprietaire.nomComplet,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            'CIN: ${vehicule.proprietaire.cin}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          Text(
            vehicule.proprietaire.telephone,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractInfo(bool isAssure, bool expireBientot) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 16, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                'Contrat d\'assurance',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicule.numeroContrat,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      vehicule.nomAssureur,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    vehicule.contrat.typeCouverture,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  if (isAssure)
                    Text(
                      expireBientot 
                          ? '${vehicule.contrat.joursRestants} jours restants'
                          : 'Valide',
                      style: TextStyle(
                        fontSize: 11,
                        color: expireBientot ? Colors.orange[700] : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
