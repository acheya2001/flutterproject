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

        // Informations collaboratives si disponibles
        if (_isCollaborativeSession()) ...[
          const SizedBox(height: 12),
          _buildCollaborativeInfo(),
        ],
      ],
    );
  }

  /// 🤝 Vérifier si c'est une session collaborative
  bool _isCollaborativeSession() {
    return sinistre['source'] == 'session' ||
           sinistre['source'] == 'collaborative_session' ||
           sinistre['codeSession'] != null ||
           sinistre['participants'] != null ||
           sinistre['estCollaboratif'] == true ||
           sinistre['type'] == 'accident_collaboratif';
  }

  /// 🤝 Informations collaboratives
  Widget _buildCollaborativeInfo() {
    final codeSession = sinistre['codeSession'] ?? sinistre['codePublic'];
    final participants = sinistre['participants'] as List<dynamic>? ?? [];
    final nombreVehicules = sinistre['nombreVehicules'] ?? participants.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête session collaborative
          Row(
            children: [
              Icon(Icons.group_work, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Text(
                'Session Collaborative',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              if (codeSession != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    codeSession,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Statistiques
          Row(
            children: [
              _buildStatChip(
                icon: Icons.directions_car,
                label: '$nombreVehicules véhicule${nombreVehicules > 1 ? 's' : ''}',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                icon: Icons.people,
                label: '${participants.length}/${nombreVehicules} rejoints',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildProgressionChip(participants),
            ],
          ),

          // Liste des participants (si disponible)
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildParticipantsList(participants),
          ],
        ],
      ),
    );
  }

  /// 📊 Chip de statistique
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 Chip de progression des formulaires avec états détaillés
  Widget _buildProgressionChip(List<dynamic> participants) {
    print('🔍 ModernSinistreCard - Participants reçus: ${participants.length}');
    for (int i = 0; i < participants.length; i++) {
      print('🔍 Participant $i: ${participants[i]}');
    }

    // Compter les différents états
    final enAttente = participants.where((p) =>
      p['formulaireStatus'] == 'en_attente' ||
      (p['formulaireStatus'] == null && p['statut'] == 'en_attente')
    ).length;

    final enCours = participants.where((p) =>
      p['formulaireStatus'] == 'en_cours' ||
      (p['formulaireStatus'] == null && p['statut'] == 'rejoint')
    ).length;

    final termines = participants.where((p) =>
      p['formulaireStatus'] == 'termine' ||
      p['statut'] == 'formulaire_fini' ||
      p['formulaireComplete'] == true
    ).length;

    final total = participants.length;

    // Déterminer la couleur principale selon la progression
    Color color;
    IconData icon;
    String texte;

    if (termines == total) {
      color = Colors.green;
      icon = Icons.check_circle;
      texte = 'Tous terminés';
    } else if (termines > 0) {
      color = Colors.orange;
      icon = Icons.pending;
      texte = '$termines/$total terminés';
    } else if (enCours > 0) {
      color = Colors.blue;
      icon = Icons.edit;
      texte = '$enCours en cours';
    } else {
      color = Colors.grey;
      icon = Icons.hourglass_empty;
      texte = '$enAttente en attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            texte,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Liste des participants
  Widget _buildParticipantsList(List<dynamic> participants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        ...participants.take(3).map((participant) => _buildParticipantRow(participant)),
        if (participants.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '... et ${participants.length - 3} autre${participants.length - 3 > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// 👤 Ligne de participant avec état du formulaire
  Widget _buildParticipantRow(dynamic participant) {
    final nom = participant['nom'] ?? participant['nomConducteur'] ?? 'Conducteur';
    final prenom = participant['prenom'] ?? '';
    final role = participant['roleVehicule'] ?? participant['role'] ?? '';
    final statut = participant['statut'] ?? 'en_attente';
    final formulaireStatus = participant['formulaireStatus'] ?? 'en_attente';
    final isCreator = participant['estCreateur'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          // Icône avec badge créateur
          Stack(
            children: [
              Icon(
                Icons.person,
                size: 12,
                color: Colors.grey[600],
              ),
              if (isCreator)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),

          // Nom et état
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${prenom.isNotEmpty ? '$prenom ' : ''}$nom${role.isNotEmpty ? ' ($role)' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: isCreator ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // État du formulaire
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getFormulaireStatusColor(formulaireStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getFormulaireStatusColor(formulaireStatus).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _getFormulaireStatusText(formulaireStatus),
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                      color: _getFormulaireStatusColor(formulaireStatus),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Indicateur de statut global
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getParticipantStatusColor(statut),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur du statut participant
  Color _getParticipantStatusColor(String statut) {
    switch (statut) {
      case 'termine':
      case 'completed':
      case 'formulaire_fini':
        return Colors.green;
      case 'en_cours':
      case 'in_progress':
      case 'rejoint':
        return Colors.orange;
      case 'en_attente':
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 🎨 Couleur de l'état du formulaire
  Color _getFormulaireStatusColor(String formulaireStatus) {
    switch (formulaireStatus) {
      case 'termine':
        return Colors.green;
      case 'en_cours':
        return Colors.blue;
      case 'en_attente':
      default:
        return Colors.grey;
    }
  }

  /// 📝 Texte de l'état du formulaire
  String _getFormulaireStatusText(String formulaireStatus) {
    switch (formulaireStatus) {
      case 'termine':
        return 'Terminé';
      case 'en_cours':
        return 'En cours';
      case 'en_attente':
      default:
        return 'En attente';
    }
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
