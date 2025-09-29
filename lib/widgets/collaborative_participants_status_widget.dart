import 'package:flutter/material.dart';
import '../models/collaborative_session_model.dart';
import '../services/collaborative_data_sync_service.dart';

/// 👥 Widget d'affichage du statut des participants en temps réel
class CollaborativeParticipantsStatusWidget extends StatelessWidget {
  final String sessionId;
  final VoidCallback? onParticipantTap;

  const CollaborativeParticipantsStatusWidget({
    Key? key,
    required this.sessionId,
    this.onParticipantTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CollaborativeSession?>(
      stream: CollaborativeDataSyncService.streamSession(sessionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Session non trouvée'),
          );
        }

        final session = snapshot.data!;
        final participants = session.participants;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Participants',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${participants.length} conducteur${participants.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progression globale
                    _buildProgressionGlobale(session.progression),
                  ],
                ),
              ),

              // Liste des participants
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: participants.map((participant) {
                    return _buildParticipantCard(participant);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 📊 Widget de progression globale
  Widget _buildProgressionGlobale(SessionProgress progression) {
    final total = progression.participantsRejoints;
    final termines = progression.formulairesTermines;
    final pourcentage = total > 0 ? (termines / total) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              value: pourcentage,
              strokeWidth: 2,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(pourcentage * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Carte d'un participant
  Widget _buildParticipantCard(SessionParticipant participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(participant.formulaireStatus).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Avatar avec rôle véhicule
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStatusColor(participant.formulaireStatus),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                participant.roleVehicule,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Informations participant
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${participant.roleVehicule} - ${participant.prenom.isNotEmpty ? participant.prenom : 'Conducteur'} ${participant.nom.isNotEmpty ? participant.nom : participant.roleVehicule}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (participant.estCreateur)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Créateur',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  participant.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(participant.formulaireStatus),
                    const SizedBox(width: 8),
                    _buildTypeChip(participant.type),
                  ],
                ),
              ],
            ),
          ),

          // Icône d'action
          if (onParticipantTap != null)
            IconButton(
              onPressed: onParticipantTap,
              icon: Icon(
                Icons.visibility,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de statut du formulaire
  Widget _buildStatusChip(FormulaireStatus status) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'],
            size: 12,
            color: config['color'],
          ),
          const SizedBox(width: 4),
          Text(
            config['label'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: config['color'],
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de type de participant
  Widget _buildTypeChip(ParticipantType type) {
    final isInscrit = type == ParticipantType.inscrit;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInscrit ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isInscrit ? 'Inscrit' : 'Invité',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isInscrit ? Colors.green[800] : Colors.orange[800],
        ),
      ),
    );
  }

  /// 🎨 Configuration du statut
  Map<String, dynamic> _getStatusConfig(FormulaireStatus status) {
    switch (status) {
      case FormulaireStatus.en_attente:
        return {
          'label': 'En attente',
          'color': Colors.grey[600],
          'icon': Icons.schedule,
        };
      case FormulaireStatus.en_cours:
        return {
          'label': 'En cours',
          'color': Colors.orange[600],
          'icon': Icons.edit,
        };
      case FormulaireStatus.termine:
        return {
          'label': 'Terminé',
          'color': Colors.green[600],
          'icon': Icons.check_circle,
        };
    }
  }

  /// 🎨 Couleur selon le statut
  Color _getStatusColor(FormulaireStatus status) {
    switch (status) {
      case FormulaireStatus.en_attente:
        return Colors.grey[600]!;
      case FormulaireStatus.en_cours:
        return Colors.orange[600]!;
      case FormulaireStatus.termine:
        return Colors.green[600]!;
    }
  }
}
