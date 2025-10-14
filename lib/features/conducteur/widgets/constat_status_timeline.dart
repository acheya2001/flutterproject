import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// 📊 Widget de timeline pour le suivi du statut du constat
class ConstatStatusTimeline extends StatelessWidget {
  final Map<String, dynamic> statusData;

  const ConstatStatusTimeline({
    Key? key,
    required this.statusData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Suivi de votre constat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline des étapes
          _buildTimelineSteps(),
        ],
      ),
    );
  }

  Widget _buildTimelineSteps() {
    final List<TimelineStep> steps = _generateTimelineSteps();

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return _buildTimelineStep(step, isLast);
      }).toList(),
    );
  }

  Widget _buildTimelineStep(TimelineStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur de statut
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: step.isCompleted ? step.color : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                size: 14,
                color: step.isCompleted ? Colors.white : Colors.grey[600],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: step.isCompleted ? step.color : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Contenu de l'étape
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: step.isCompleted ? Colors.black87 : Colors.grey[600],
                ),
              ),
              if (step.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  step.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (step.date != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDate(step.date!),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              if (step.actionWidget != null) ...[
                const SizedBox(height: 8),
                step.actionWidget!,
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  List<TimelineStep> _generateTimelineSteps() {
    final List<TimelineStep> steps = [];
    final statut = statusData['statut'] ?? '';

    // Étape 1: Constat finalisé
    steps.add(TimelineStep(
      title: 'Constat finalisé',
      subtitle: 'Votre constat a été complété et signé',
      icon: Icons.check_circle,
      color: Colors.green,
      isCompleted: true,
      date: statusData['dateEnvoi'],
    ));

    // Étape 2: Envoyé à l'agent
    final isEnvoye = ['envoye', 'envoye_agent', 'nouveau', 'en_cours', 'traite', 'expert_assigne', 'en_expertise', 'expertise_terminee'].contains(statut);
    steps.add(TimelineStep(
      title: 'Envoyé à l\'agent',
      subtitle: statusData['agentInfo'] != null 
          ? 'Agent: ${statusData['agentInfo']['prenom']} ${statusData['agentInfo']['nom']}'
          : 'Transmis à votre agent d\'assurance',
      icon: Icons.send,
      color: Colors.blue,
      isCompleted: isEnvoye,
      date: statusData['dateEnvoi'],
    ));

    // Étape 3: Traitement par l'agent
    final isTraite = ['traite', 'expert_assigne', 'en_expertise', 'expertise_terminee'].contains(statut);
    steps.add(TimelineStep(
      title: 'Traitement par l\'agent',
      subtitle: _getTraitementSubtitle(statut),
      icon: Icons.pending_actions,
      color: Colors.orange,
      isCompleted: isTraite,
      date: statusData['dateTraitement'],
    ));

    // Étape 4: Expert assigné (si applicable)
    if (statusData['expertAssigne'] != null) {
      final isExpertAssigne = ['expert_assigne', 'en_expertise', 'expertise_terminee'].contains(statut);
      final expertNom = '${statusData['expertAssigne']['prenom']} ${statusData['expertAssigne']['nom']}';
      steps.add(TimelineStep(
        title: 'Expert assigné',
        subtitle: 'Expert: $expertNom',
        icon: Icons.engineering,
        color: Colors.purple,
        isCompleted: isExpertAssigne,
        date: statusData['dateAssignationExpert'],
        actionWidget: statusData['expertAssigne']['telephone'] != null
            ? _buildCallExpertButton(statusData['expertAssigne']['telephone'])
            : null,
      ));

      // Étape 5: Expertise en cours/terminée
      final isExpertiseTerminee = statut == 'expertise_terminee';
      steps.add(TimelineStep(
        title: isExpertiseTerminee ? 'Expertise terminée' : 'Expertise en cours',
        subtitle: isExpertiseTerminee 
            ? 'Rapport d\'expertise disponible'
            : 'L\'expert examine votre véhicule',
        icon: isExpertiseTerminee ? Icons.check_circle : Icons.assessment,
        color: isExpertiseTerminee ? Colors.green : Colors.deepPurple,
        isCompleted: ['en_expertise', 'expertise_terminee'].contains(statut),
        date: statusData['dateVisite'],
      ));
    }

    return steps;
  }

  String _getTraitementSubtitle(String statut) {
    switch (statut) {
      case 'nouveau':
        return 'Dossier reçu, en attente de traitement';
      case 'en_cours':
        return 'Votre dossier est en cours d\'analyse';
      case 'traite':
        return 'Dossier traité avec succès';
      case 'expert_assigne':
        return 'Un expert a été assigné à votre dossier';
      default:
        return 'En cours de traitement';
    }
  }

  Widget _buildCallExpertButton(String telephone) {
    return Builder(
      builder: (context) => OutlinedButton.icon(
        onPressed: () => _callExpert(telephone),
        icon: const Icon(Icons.phone, size: 16),
        label: const Text('Appeler'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.purple[600],
          side: BorderSide(color: Colors.purple[600]!),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
    );
  }

  void _callExpert(String telephone) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: telephone,
      );
      await launchUrl(launchUri);
    } catch (e) {
      print('Erreur lors de l\'appel: $e');
    }
  }

  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return '';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

/// 📋 Modèle pour une étape de la timeline
class TimelineStep {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final dynamic date;
  final Widget? actionWidget;

  TimelineStep({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.isCompleted,
    this.date,
    this.actionWidget,
  });
}
