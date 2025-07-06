import 'package:flutter/material.dart';
import '../models/vehicule_assure_model.dart';

/// 🚗 Widget carte pour afficher un véhicule assuré
class VehicleCard extends StatelessWidget {
  final VehiculeAssureModel vehicule;
  final VoidCallback onTap;
  final bool isLoading;
  final bool showOwnerInfo;

  const VehicleCard({
    super.key,
    required this.vehicule,
    required this.onTap,
    this.isLoading = false,
    this.showOwnerInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec photo et infos principales
              _buildHeader(),
              
              const SizedBox(height: 12),
              
              // Informations du véhicule
              _buildVehicleInfo(),
              
              const SizedBox(height: 12),
              
              // Informations du contrat
              _buildContractInfo(),

              // Informations du propriétaire (pour les assureurs)
              if (showOwnerInfo) ...[
                const SizedBox(height: 12),
                _buildOwnerInfo(),
              ],

              const SizedBox(height: 12),

              // Statut et actions
              _buildStatusAndActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 En-tête avec photo et infos principales
  Widget _buildHeader() {
    return Row(
      children: [
        // Photo du véhicule (placeholder)
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getVehicleColor(),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 32,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Informations principales
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vehicule.vehicule.marque} ${vehicule.vehicule.modele}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vehicule.vehicule.immatriculation,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${vehicule.vehicule.annee} • ${vehicule.vehicule.couleur}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        
        // Indicateur de chargement ou flèche
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.purple,
            ),
          )
        else
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
      ],
    );
  }

  /// 🚗 Informations du véhicule
  Widget _buildVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoItem(
              icon: Icons.settings,
              label: 'Puissance',
              value: '${vehicule.vehicule.puissanceFiscale} CV',
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.calendar_today,
              label: 'Année',
              value: vehicule.vehicule.annee.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildInfoItem(
              icon: Icons.palette,
              label: 'Couleur',
              value: vehicule.vehicule.couleur,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Informations du propriétaire
  Widget _buildOwnerInfo() {
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
              Icon(Icons.person, color: Colors.green[700], size: 16),
              const SizedBox(width: 6),
              Text(
                'Propriétaire',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOwnerItem(
                  'Nom',
                  '${vehicule.proprietaire.prenom} ${vehicule.proprietaire.nom}',
                ),
              ),
              Expanded(
                child: _buildOwnerItem(
                  'CIN',
                  vehicule.proprietaire.cin,
                ),
              ),
            ],
          ),
          if (vehicule.proprietaire.telephone.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildOwnerItem(
              'Téléphone',
              vehicule.proprietaire.telephone,
            ),
          ],
        ],
      ),
    );
  }

  /// 📄 Informations du contrat
  Widget _buildContractInfo() {
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
              Icon(Icons.shield, color: Colors.blue[700], size: 16),
              const SizedBox(width: 6),
              Text(
                _getAssureurName(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildContractItem(
                  'Contrat',
                  vehicule.numeroContrat,
                ),
              ),
              Expanded(
                child: _buildContractItem(
                  'Couverture',
                  vehicule.contrat.typeCouverture,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildContractItem(
                  'Franchise',
                  '${vehicule.contrat.franchise.toInt()} TND',
                ),
              ),
              Expanded(
                child: _buildContractItem(
                  'Expire le',
                  _formatDate(vehicule.contrat.dateFin),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Statut et actions
  Widget _buildStatusAndActions() {
    final isActive = vehicule.isContratActif;
    final daysRemaining = vehicule.contrat.dateFin.difference(DateTime.now()).inDays;
    
    return Row(
      children: [
        // Statut du contrat
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.error,
                color: isActive ? Colors.green[700] : Colors.red[700],
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isActive ? 'Actif' : 'Expiré',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Jours restants
        if (isActive && daysRemaining <= 30)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$daysRemaining jours restants',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ),
        
        const Spacer(),
        
        // Nombre de sinistres
        if (vehicule.historiqueSinistres.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text(
                  '${vehicule.historiqueSinistres.length} sinistre${vehicule.historiqueSinistres.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 📊 Widget item d'information
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 📄 Widget item de contrat
  Widget _buildContractItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.blue[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 👤 Widget item de propriétaire
  Widget _buildOwnerItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.green[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 🎨 Couleur du véhicule
  Color _getVehicleColor() {
    switch (vehicule.vehicule.couleur.toLowerCase()) {
      case 'rouge':
        return Colors.red;
      case 'bleu':
        return Colors.blue;
      case 'vert':
        return Colors.green;
      case 'jaune':
        return Colors.yellow[700]!;
      case 'noir':
        return Colors.black;
      case 'blanc':
        return Colors.grey[300]!;
      case 'gris':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  /// 🏢 Nom de l'assureur
  String _getAssureurName() {
    switch (vehicule.assureurId.toUpperCase()) {
      case 'STAR':
        return 'STAR Assurances';
      case 'MAGHREBIA':
        return 'Maghrebia Assurances';
      case 'GAT':
        return 'GAT Assurances';
      case 'LLOYD':
        return 'Lloyd Tunisien';
      case 'ASTREE':
        return 'Astrée Assurances';
      default:
        return vehicule.assureurId;
    }
  }

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
}
