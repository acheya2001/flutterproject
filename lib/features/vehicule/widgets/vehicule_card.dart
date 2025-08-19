import 'package:flutter/material.dart';
import '../models/vehicule_assure_model.dart';

class VehiculeCard extends StatelessWidget {
  final VehiculeAssureModel vehicule;
  final VoidCallback? onTap;

  const VehiculeCard({
    super.key,
    required this.vehicule,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Déterminer le statut et la couleur
    String statusText;
    Color statusColor;

    if (vehicule.contrat.estExpire) {
      statusText = 'Expiré';
      statusColor = Colors.red;
    } else if (vehicule.contrat.expireBientot) {
      statusText = 'Expire bientôt';
      statusColor = Colors.orange;
    } else {
      statusText = 'Assuré';
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec immatriculation et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vehicule.vehicule.immatriculation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description du véhicule
              Text(
                vehicule.descriptionVehicule,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Informations détaillées
              _buildInfoRow('Couleur', vehicule.vehicule.couleur),
              _buildInfoRow('Année', vehicule.vehicule.annee.toString()),
              _buildInfoRow('Carburant', vehicule.vehicule.typeCarburant),
              _buildInfoRow('Puissance', '${vehicule.vehicule.puissanceFiscale} CV'),

              const Divider(height: 20),

              // Propriétaire
              _buildInfoRow('Propriétaire', vehicule.proprietaire.nomComplet),
              _buildInfoRow('CIN', vehicule.proprietaire.cin),

              const Divider(height: 20),

              // Contrat d'assurance
              _buildInfoRow('Contrat d\'assurance', vehicule.numeroContrat),
              _buildInfoRow('Assureur', vehicule.nomAssureur),
              _buildInfoRow(
                'Validité',
                vehicule.contrat.expireBientot
                    ? '${vehicule.contrat.joursRestants} jours restants'
                    : 'Valide',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}