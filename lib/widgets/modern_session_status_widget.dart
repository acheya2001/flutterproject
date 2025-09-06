import 'package:flutter/material.dart';
import '../services/session_status_service.dart';

/// 📊 Widget moderne pour afficher le statut d'une session en temps réel
class ModernSessionStatusWidget extends StatelessWidget {
  final String sessionId;
  final bool showDetails;

  const ModernSessionStatusWidget({
    Key? key,
    required this.sessionId,
    this.showDetails = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: SessionStatusService.getSessionStatusStream(sessionId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return _buildLoadingWidget();
        }

        final data = snapshot.data!;
        
        if (!data['exists']) {
          return _buildNotFoundWidget();
        }

        return _buildStatusWidget(data);
      },
    );
  }

  Widget _buildStatusWidget(Map<String, dynamic> data) {
    final statut = data['statut'] as String;
    final totalParticipants = data['totalParticipants'] as int;
    final participantsRejoints = data['participantsRejoints'] as int;
    final participantsTermines = data['participantsTermines'] as int;
    final participants = data['participants'] as List<Map<String, dynamic>>;

    final statusColor = _getStatusColor(statut);
    final progression = totalParticipants > 0 
        ? (participantsTermines / totalParticipants * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(statut),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SessionStatusService.getStatusLabel(statut),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (showDetails) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$participantsRejoints/$totalParticipants participants',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showDetails)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$progression%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),

          if (showDetails) ...[
            const SizedBox(height: 16),

            // Barre de progression
            _buildProgressBar(progression, statusColor),

            const SizedBox(height: 16),

            // Liste des participants
            _buildParticipantsList(participants),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(int progression, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progression',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$progression%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progression / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildParticipantsList(List<Map<String, dynamic>> participants) {
    if (participants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
            const SizedBox(width: 8),
            const Text(
              'Aucun participant pour le moment',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Participants',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...participants.map((participant) => _buildParticipantItem(participant)).toList(),
      ],
    );
  }

  Widget _buildParticipantItem(Map<String, dynamic> participant) {
    final aRejoint = participant['aRejoint'] ?? false;
    final formulaireComplete = participant['formulaireComplete'] ?? false;
    final isInscrit = participant['isInscrit'] ?? false;

    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (formulaireComplete) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusText = 'Terminé';
    } else if (aRejoint) {
      statusIcon = Icons.edit;
      statusColor = Colors.blue;
      statusText = 'En cours';
    } else {
      statusIcon = Icons.schedule;
      statusColor = Colors.orange;
      statusText = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant['nom'] ?? 'Participant',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isInscrit ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isInscrit ? 'Inscrit' : 'Invité',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isInscrit ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Chargement du statut...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Erreur: $error',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, color: Colors.grey[600]),
          const SizedBox(width: 12),
          const Text('Session non trouvée'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case SessionStatusService.STATUS_EN_ATTENTE_PARTICIPANTS:
        return Colors.orange;
      case SessionStatusService.STATUS_EN_COURS_REMPLISSAGE:
        return Colors.blue;
      case SessionStatusService.STATUS_TERMINE:
        return Colors.green;
      case SessionStatusService.STATUS_ENVOYE_AGENCE:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case SessionStatusService.STATUS_EN_ATTENTE_PARTICIPANTS:
        return Icons.schedule;
      case SessionStatusService.STATUS_EN_COURS_REMPLISSAGE:
        return Icons.edit;
      case SessionStatusService.STATUS_TERMINE:
        return Icons.check_circle;
      case SessionStatusService.STATUS_ENVOYE_AGENCE:
        return Icons.send;
      default:
        return Icons.help_outline;
    }
  }
}
