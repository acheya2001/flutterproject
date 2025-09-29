import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🐛 Widget de debug pour afficher les informations de session en temps réel
class SessionDebugInfo extends StatelessWidget {
  final String sessionId;
  final bool showDetails;

  const SessionDebugInfo({
    Key? key,
    required this.sessionId,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('❌ Session non trouvée'),
            ),
          );
        }

        final sessionData = snapshot.data!.data() as Map<String, dynamic>;
        final participants = List.from(sessionData['participants'] ?? []);
        final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
        final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

        // Calculer les vraies statistiques
        final vraiParticipantsRejoints = participants.length;
        final vraiFormulairesTermines = participants.where((p) =>
          p['statut'] == 'formulaire_fini' ||
          p['formulaireStatus'] == 'termine'
        ).length;

        // Statistiques de la progression
        final progressionParticipants = progression['participantsRejoints'] ?? 0;
        final progressionFormulaires = progression['formulairesTermines'] ?? 0;

        // Détecter les problèmes
        final hasProblems = vraiParticipantsRejoints != progressionParticipants ||
                           vraiFormulairesTermines != progressionFormulaires;

        return Card(
          color: hasProblems ? Colors.orange[50] : Colors.green[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasProblems ? Icons.warning : Icons.check_circle,
                      color: hasProblems ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasProblems ? '🐛 Problèmes détectés' : '✅ Session OK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: hasProblems ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    if (showDetails)
                      Text(
                        'ID: ${sessionId.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Informations principales
                _buildInfoRow('🚗 Véhicules attendus', '$nombreVehicules'),
                _buildInfoRow('🔄 Statut', '${sessionData['statut']}'),
                
                const SizedBox(height: 8),
                
                // Comparaison participants
                _buildComparisonRow(
                  '👥 Participants',
                  vraiParticipantsRejoints,
                  progressionParticipants,
                  nombreVehicules,
                ),
                
                // Comparaison formulaires
                _buildComparisonRow(
                  '📋 Formulaires terminés',
                  vraiFormulairesTermines,
                  progressionFormulaires,
                  nombreVehicules,
                ),
                
                if (showDetails) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Détails des participants
                  const Text(
                    'Participants:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...participants.asMap().entries.map((entry) {
                    final index = entry.key;
                    final participant = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2),
                      child: Text(
                        '${index + 1}. ${participant['prenom']} ${participant['nom']} '
                        '(${participant['roleVehicule']}) - ${participant['statut']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 8),
                  
                  // Progression détaillée
                  const Text(
                    'Progression:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Croquis validés: ${progression['croquisValides'] ?? 0}', style: const TextStyle(fontSize: 12)),
                        Text('Signatures: ${progression['signaturesEffectuees'] ?? 0}', style: const TextStyle(fontSize: 12)),
                        Text('Pourcentage: ${progression['pourcentage'] ?? 0}%', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, int real, int progression, int total) {
    final hasError = real != progression;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$real/$total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                    color: hasError ? Colors.red : Colors.green,
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($progression)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.error,
                    size: 16,
                    color: Colors.red[600],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔧 Widget de debug compact pour la barre d'état
class SessionDebugBadge extends StatelessWidget {
  final String sessionId;
  final VoidCallback? onTap;

  const SessionDebugBadge({
    Key? key,
    required this.sessionId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final sessionData = snapshot.data!.data() as Map<String, dynamic>;
        final participants = List.from(sessionData['participants'] ?? []);
        final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};

        final vraiParticipantsRejoints = participants.length;
        final progressionParticipants = progression['participantsRejoints'] ?? 0;

        final hasProblems = vraiParticipantsRejoints != progressionParticipants;

        if (!hasProblems) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bug_report, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  'Debug',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🔧 Dialog de debug complet
class SessionDebugDialog extends StatelessWidget {
  final String sessionId;

  const SessionDebugDialog({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  static void show(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => SessionDebugDialog(sessionId: sessionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Debug Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SessionDebugInfo(
                  sessionId: sessionId,
                  showDetails: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
