import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/sinistre_tracking_service.dart';

/// 🎨 Carte moderne et élégante pour afficher un sinistre
class ModernSinistreCard extends StatelessWidget {
  final Map<String, dynamic> sinistre;
  final VoidCallback? onTap;
  final bool showActions;

  const ModernSinistreCard({
    Key? key,
    required this.sinistre,
    this.onTap,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statut = sinistre['statut'] ?? 'en_attente';
    final statutInfo = SinistreTrackingService.getStatutInfo(statut);
    final progression = sinistre['progression'] ?? 0;
    final dateCreation = sinistre['dateCreation'] as Timestamp?;
    final lieu = sinistre['lieu'] ?? 'Lieu non défini';
    final type = sinistre['type'] ?? 'accident_route';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(statutInfo['color']).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut et date
                _buildHeader(statutInfo, dateCreation),
                
                const SizedBox(height: 16),
                
                // Informations principales
                _buildMainInfo(type, lieu),
                
                const SizedBox(height: 16),
                
                // Barre de progression
                _buildProgressBar(progression, statutInfo),
                
                if (showActions) ...[
                  const SizedBox(height: 16),
                  _buildActions(context, statut),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 📋 En-tête avec statut et date
  Widget _buildHeader(Map<String, dynamic> statutInfo, Timestamp? dateCreation) {
    return Row(
      children: [
        // Badge de statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(statutInfo['color']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(statutInfo['color']).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconData(statutInfo['icon']),
                size: 16,
                color: Color(statutInfo['color']),
              ),
              const SizedBox(width: 6),
              Text(
                statutInfo['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(statutInfo['color']),
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Date
        if (dateCreation != null)
          Text(
            DateFormat('dd/MM/yyyy à HH:mm').format(dateCreation.toDate()),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  /// 📍 Informations principales
  Widget _buildMainInfo(String type, String lieu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type d'accident
        Row(
          children: [
            Icon(
              _getTypeIcon(type),
              size: 20,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              _getTypeLabel(type),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Lieu
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lieu,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Barre de progression
  Widget _buildProgressBar(int progression, Map<String, dynamic> statutInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '$progression%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(statutInfo['color']),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progression / 100,
            child: Container(
              decoration: BoxDecoration(
                color: Color(statutInfo['color']),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎯 Actions disponibles
  Widget _buildActions(BuildContext context, String statut) {
    final actions = <Widget>[];

    switch (statut) {
      case 'en_attente':
        actions.add(_buildActionButton(
          'Continuer',
          Icons.play_arrow,
          Colors.blue[600]!,
          () => _continuerSinistre(context),
        ));
        break;
        
      case 'en_cours':
        actions.add(_buildActionButton(
          'Reprendre',
          Icons.edit,
          Colors.orange[600]!,
          () => _reprendreSinistre(context),
        ));
        break;
        
      case 'termine':
      case 'envoye_agence':
        actions.add(_buildActionButton(
          'Voir détails',
          Icons.visibility,
          Colors.green[600]!,
          () => _voirDetails(context),
        ));
        break;
        
      default:
        actions.add(_buildActionButton(
          'Ouvrir',
          Icons.open_in_new,
          Colors.grey[600]!,
          () => _ouvrirSinistre(context),
        ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        ...actions,
        const Spacer(),
        _buildActionButton(
          'Plus',
          Icons.more_horiz,
          Colors.grey[500]!,
          () => _showMoreActions(context),
        ),
      ],
    );
  }

  /// 🔘 Bouton d'action
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          backgroundColor: color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 🎨 Obtenir l'icône pour un statut
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'pending': return Icons.pending;
      case 'edit': return Icons.edit;
      case 'draft': return Icons.drafts;
      case 'check_circle': return Icons.check_circle;
      case 'send': return Icons.send;
      case 'assessment': return Icons.assessment;
      case 'archive': return Icons.archive;
      default: return Icons.info;
    }
  }

  /// 🚗 Obtenir l'icône pour un type d'accident
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'accident_route': return Icons.car_crash;
      case 'accident_parking': return Icons.local_parking;
      case 'accident_multiple': return Icons.multiple_stop;
      default: return Icons.warning;
    }
  }

  /// 📝 Obtenir le label pour un type d'accident
  String _getTypeLabel(String type) {
    switch (type) {
      case 'accident_route': return 'Accident de la route';
      case 'accident_parking': return 'Accident de parking';
      case 'accident_multiple': return 'Accident multiple';
      default: return 'Sinistre';
    }
  }

  /// ▶️ Actions des boutons
  void _continuerSinistre(BuildContext context) {
    // TODO: Naviguer vers la suite du processus
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continuer le sinistre - À implémenter')),
    );
  }

  void _reprendreSinistre(BuildContext context) {
    // TODO: Reprendre le remplissage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reprendre le sinistre - À implémenter')),
    );
  }

  void _voirDetails(BuildContext context) {
    // TODO: Afficher les détails complets
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voir détails - À implémenter')),
    );
  }

  void _ouvrirSinistre(BuildContext context) {
    // TODO: Ouvrir le sinistre
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouvrir sinistre - À implémenter')),
    );
  }

  void _showMoreActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Partager'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Télécharger PDF'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
