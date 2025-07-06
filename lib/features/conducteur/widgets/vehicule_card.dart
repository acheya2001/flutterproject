import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../vehicule/models/vehicule_model.dart';
import '../../vehicule/screens/vehicule_detail_screen.dart';

class VehiculeCard extends StatelessWidget {
  final VehiculeModel vehicule;
  final VoidCallback? onTap; // Optionnel maintenant
  final Color cardColor;
  final Color accentColor;
  final int index; // Pour les couleurs dynamiques

  const VehiculeCard({
    Key? key,
    required this.vehicule,
    this.onTap, // Optionnel
    required this.cardColor,
    required this.accentColor,
    required this.index, // Nouveau paramètre
  }) : super(key: key);

  // Couleurs dynamiques pour chaque véhicule - Vert et Rose en premier comme demandé
  static const List<List<Color>> _vehicleColorSchemes = [
    [Color(0xFF81C784), Color(0xFFE8F5E8), Color(0xFF388E3C)], // Vert (1er véhicule)
    [Color(0xFFF06292), Color(0xFFFCE4EC), Color(0xFFC2185B)], // Rose (2ème véhicule)
    [Color(0xFF64B5F6), Color(0xFFE3F2FD), Color(0xFF1976D2)], // Bleu
    [Color(0xFFFFB74D), Color(0xFFFFF3E0), Color(0xFFF57C00)], // Orange
    [Color(0xFFBA68C8), Color(0xFFF3E5F5), Color(0xFF7B1FA2)], // Violet
    [Color(0xFF4DB6AC), Color(0xFFE0F2F1), Color(0xFF00695C)], // Teal
    [Color(0xFF90A4AE), Color(0xFFECEFF1), Color(0xFF455A64)], // Gris bleu
    [Color(0xFFA1887F), Color(0xFFEFEBE9), Color(0xFF5D4037)], // Marron
  ];

  List<Color> _getVehicleColors() {
    final colorIndex = index % _vehicleColorSchemes.length;
    return _vehicleColorSchemes[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final isExpired = vehicule.dateFinValidite != null && vehicule.dateFinValidite!.isBefore(now);

    // Couleurs dynamiques selon l'index du véhicule
    final vehicleColors = _getVehicleColors();
    final primaryColor = vehicleColors[0];
    final lightColor = vehicleColors[1];
    final darkColor = vehicleColors[2];

    // Couleurs selon l'état (expiré = rouge, sinon couleur dynamique)
    Color buttonColor = isExpired
        ? const Color(0xFFFF7A7A) // Rouge pour expiré
        : primaryColor; // Couleur dynamique pour valide

    String statusText = isExpired ? 'Expiré' : 'Valide';
    Color statusBgColor = isExpired
        ? const Color(0xFFFFEBEE) // Rouge clair pour expiré
        : lightColor; // Couleur dynamique claire pour valide
    Color statusTextColor = isExpired
        ? const Color(0xFFD32F2F) // Rouge foncé pour expiré
        : darkColor; // Couleur dynamique foncée pour valide

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec badge statut et immatriculation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge de statut
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Immatriculation
              Text(
                vehicule.immatriculation,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isExpired ? const Color(0xFFFF7A7A) : const Color(0xFF81C784),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations du véhicule en grille 2x2
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(
                      Icons.directions_car_outlined,
                      'Marque',
                      vehicule.marque.isNotEmpty ? vehicule.marque : 'Non spécifié',
                      primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.security_outlined,
                      'Assureur',
                      vehicule.compagnieAssurance.isNotEmpty ? vehicule.compagnieAssurance : 'Non spécifié',
                      primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(
                      Icons.car_rental_outlined,
                      'Modèle',
                      vehicule.modele.isNotEmpty ? vehicule.modele : 'Non spécifié',
                      primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.calendar_today_outlined,
                      'Validité',
                      vehicule.dateFinValidite != null ? dateFormat.format(vehicule.dateFinValidite!) : 'Non spécifié',
                      isExpired ? const Color(0xFFFF7A7A) : primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Boutons d'action
          Row(
            children: [
              // Bouton "Voir les détails"
              Expanded(
                flex: 2,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        // Navigation vers l'écran de détails SEULEMENT
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehiculeDetailScreen(vehicule: vehicule),
                          ),
                        );
                      },
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Voir les détails',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bouton "Déclarer un sinistre" (si onTap est fourni)
              if (onTap != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: onTap,
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.report_problem_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Déclarer un sinistre',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}