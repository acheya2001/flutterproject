import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🚨 Widget d'alerte pour le statut des sessions
class SessionStatusAlert extends StatefulWidget {
  final String sessionId;
  final VoidCallback? onRefresh;

  const SessionStatusAlert({
    Key? key,
    required this.sessionId,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<SessionStatusAlert> createState() => _SessionStatusAlertState();
}

class _SessionStatusAlertState extends State<SessionStatusAlert> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .doc(widget.sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final sessionData = snapshot.data!.data() as Map<String, dynamic>;
        final participants = List.from(sessionData['participants'] ?? []);
        final nombreVehicules = sessionData['nombreVehicules'] ?? 2;
        final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
        final statut = sessionData['statut'] as String? ?? 'inconnu';

        // Analyser les problèmes potentiels
        final problems = _analyzeSessionProblems(
          participants: participants,
          nombreVehicules: nombreVehicules,
          progression: progression,
          statut: statut,
        );

        if (problems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            color: Colors.orange[50],
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Problèmes détectés dans la session',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onRefresh,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualiser',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...problems.map((problem) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          problem['icon'] as IconData,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            problem['message'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDetailedInfo(context, sessionData),
                          icon: const Icon(Icons.info, size: 16),
                          label: const Text('Voir détails'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(color: Colors.orange[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showRepairOptions(context),
                          icon: const Icon(Icons.build, size: 16),
                          label: const Text('Corriger'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔍 Analyser les problèmes de la session
  List<Map<String, dynamic>> _analyzeSessionProblems({
    required List<dynamic> participants,
    required int nombreVehicules,
    required Map<String, dynamic> progression,
    required String statut,
  }) {
    final problems = <Map<String, dynamic>>[];

    // Problème 1: Nombre de participants incorrect
    final participantsRejoints = progression['participantsRejoints'] ?? 0;
    if (participants.length != participantsRejoints) {
      problems.add({
        'icon': Icons.people,
        'message': 'Comptage des participants incorrect (${participants.length} vs $participantsRejoints)',
      });
    }

    // Problème 2: Participants manquants
    if (participants.length < nombreVehicules) {
      final manquants = nombreVehicules - participants.length;
      problems.add({
        'icon': Icons.person_add,
        'message': '$manquants participant(s) manquant(s) pour compléter la session',
      });
    }

    // Problème 3: Formulaires terminés non comptabilisés
    final formulairesTerminesReel = participants.where((p) =>
      p['formulaireComplete'] == true ||
      p['statut'] == 'formulaire_fini' ||
      p['formulaireStatus'] == 'termine'
    ).length;
    final formulairesTerminesProgression = progression['formulairesTermines'] ?? 0;
    
    if (formulairesTerminesReel != formulairesTerminesProgression) {
      problems.add({
        'icon': Icons.assignment,
        'message': 'Formulaires terminés non comptabilisés ($formulairesTerminesReel vs $formulairesTerminesProgression)',
      });
    }

    // Problème 4: Statut incohérent
    if (participants.length >= nombreVehicules && formulairesTerminesReel >= nombreVehicules) {
      if (statut == 'en_attente' || statut == 'attente_participants') {
        problems.add({
          'icon': Icons.sync_problem,
          'message': 'Statut de session incohérent (devrait être "validation_croquis" ou "en_cours")',
        });
      }
    }

    // Problème 5: Progression bloquée
    if (statut == 'en_attente' && participants.isNotEmpty) {
      problems.add({
        'icon': Icons.hourglass_empty,
        'message': 'Session bloquée en attente malgré la présence de participants',
      });
    }

    return problems;
  }

  /// 📊 Afficher les informations détaillées
  void _showDetailedInfo(BuildContext context, Map<String, dynamic> sessionData) {
    final participants = List.from(sessionData['participants'] ?? []);
    final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Détails de la session'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('🚗 Véhicules attendus', '$nombreVehicules'),
              _buildInfoRow('👥 Participants actuels', '${participants.length}'),
              _buildInfoRow('📊 Participants (progression)', '${progression['participantsRejoints'] ?? 0}'),
              _buildInfoRow('📋 Formulaires terminés', '${progression['formulairesTermines'] ?? 0}'),
              _buildInfoRow('📈 Pourcentage', '${progression['pourcentage'] ?? 0}%'),
              _buildInfoRow('🔄 Statut', '${sessionData['statut']}'),
              const SizedBox(height: 16),
              const Text(
                'Participants:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...participants.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${index + 1}. ${participant['prenom']} ${participant['nom']} (${participant['statut'] ?? 'inconnu'})',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  /// 🔧 Afficher les options de réparation
  void _showRepairOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.build, color: Colors.orange),
            SizedBox(width: 8),
            Text('Options de correction'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Que souhaitez-vous faire ?'),
            SizedBox(height: 16),
            Text(
              '• Actualiser les données : Recharge les informations de la session',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '• Réparer automatiquement : Corrige les problèmes de comptage détectés',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '• Contacter le support : Si les problèmes persistent',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRefresh?.call();
            },
            child: const Text('Actualiser'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performAutoRepair();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réparer'),
          ),
        ],
      ),
    );
  }

  /// 🔧 Effectuer une réparation automatique
  void _performAutoRepair() async {
    // Ici vous pourriez appeler le service de réparation
    // ou afficher le widget SessionRepairButton
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Utilisez le bouton de réparation ci-dessous pour corriger les problèmes'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
