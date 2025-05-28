import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/vehicule_model.dart';
import '../providers/vehicule_provider.dart';
import 'vehicule_form_screen.dart';

class VehiculeDetailScreen extends StatelessWidget {
  final VehiculeModel vehicule;

  const VehiculeDetailScreen({Key? key, required this.vehicule}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          vehicule.immatriculation,
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF718096), size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de partage à implémenter'),
                  backgroundColor: Color(0xFF4A5568),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos section
            if (vehicule.photoCarteGriseRecto != null || vehicule.photoCarteGriseVerso != null)
              _buildPhotosSection(),
            
            const SizedBox(height: 16),
            
            // Vehicle info card
            _buildInfoCard(
              title: 'Informations du véhicule',
              icon: Icons.directions_car_outlined,
              children: [
                _buildInfoRow('Immatriculation', vehicule.immatriculation),
                _buildInfoRow('Marque', vehicule.marque.isNotEmpty ? vehicule.marque : 'Non spécifié'),
                _buildInfoRow('Modèle', vehicule.modele.isNotEmpty ? vehicule.modele : 'Non spécifié'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Insurance info card
            _buildInfoCard(
              title: 'Informations d\'assurance',
              icon: Icons.security_outlined,
              children: [
                _buildInfoRow('Compagnie', vehicule.compagnieAssurance.isNotEmpty ? vehicule.compagnieAssurance : 'Non spécifié'),
                _buildInfoRow('N° de contrat', vehicule.numeroContrat.isNotEmpty ? vehicule.numeroContrat : 'Non spécifié'),
                _buildInfoRow('Agence', vehicule.agence.isNotEmpty ? vehicule.agence : 'Non spécifié'),
                _buildInfoRow(
                  'Début de validité',
                  vehicule.dateDebutValidite != null ? dateFormat.format(vehicule.dateDebutValidite!) : 'Non spécifié',
                ),
                _buildInfoRow(
                  'Fin de validité',
                  vehicule.dateFinValidite != null ? dateFormat.format(vehicule.dateFinValidite!) : 'Non spécifié',
                ),
              ],
            ),
            
            if (vehicule.dateFinValidite != null) ...[
              const SizedBox(height: 16),
              _buildStatusCard(vehicule.dateFinValidite!),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 18, color: const Color(0xFF718096)),
                const SizedBox(width: 8),
                Text(
                  'Photos de la carte grise',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                if (vehicule.photoCarteGriseRecto != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: vehicule.photoCarteGriseRecto!,
                          fit: BoxFit.cover,
                          height: 144,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF7FAFC),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFFED7D7),
                            child: const Center(
                              child: Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (vehicule.photoCarteGriseRecto != null && vehicule.photoCarteGriseVerso != null)
                  const SizedBox(width: 8),
                if (vehicule.photoCarteGriseVerso != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: vehicule.photoCarteGriseVerso!,
                          fit: BoxFit.cover,
                          height: 144,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF7FAFC),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFFED7D7),
                            child: const Center(
                              child: Icon(Icons.error_outline, color: Color(0xFFE53E3E), size: 24),
                            ),
                          ),
                        ),
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

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF718096)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(DateTime dateFinValidite) {
    final now = DateTime.now();
    final difference = dateFinValidite.difference(now).inDays;
    
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    String statusText;
    IconData statusIcon;
    
    if (dateFinValidite.isBefore(now)) {
      backgroundColor = const Color(0xFFFED7D7);
      textColor = const Color(0xFFE53E3E);
      iconColor = const Color(0xFFE53E3E);
      statusText = 'Assurance expirée';
      statusIcon = Icons.error_outline;
    } else if (difference <= 30) {
      backgroundColor = const Color(0xFFFEEBC8);
      textColor = const Color(0xFFD69E2E);
      iconColor = const Color(0xFFD69E2E);
      statusText = 'Expire dans $difference jours';
      statusIcon = Icons.warning_amber_outlined;
    } else {
      backgroundColor = const Color(0xFFC6F6D5);
      textColor = const Color(0xFF38A169);
      iconColor = const Color(0xFF38A169);
      statusText = 'Valide ($difference jours restants)';
      statusIcon = Icons.check_circle_outline;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4299E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _editVehicule(context),
                child: const Center(
                  child: Text(
                    'Modifier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _deleteVehicule(context),
                child: const Center(
                  child: Text(
                    'Supprimer',
                    style: TextStyle(
                      color: Color(0xFFE53E3E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editVehicule(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehiculeFormScreen(vehicule: vehicule),
      ),
    );
    
    if (result == true && context.mounted) {
      final vehiculeProvider = Provider.of<VehiculeProvider>(context, listen: false);
      await vehiculeProvider.fetchVehiculesByProprietaireId(vehicule.proprietaireId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Véhicule mis à jour avec succès'),
            backgroundColor: Color(0xFF38A169),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _deleteVehicule(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirmation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce véhicule ?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFF718096), fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Color(0xFFE53E3E), fontSize: 14),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      try {
        final vehiculeProvider = Provider.of<VehiculeProvider>(context, listen: false);
        await vehiculeProvider.deleteVehicule(vehicule.id!, vehicule.proprietaireId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Véhicule supprimé avec succès'),
              backgroundColor: Color(0xFF38A169),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: const Color(0xFFE53E3E),
            ),
          );
        }
      }
    }
  }
}
