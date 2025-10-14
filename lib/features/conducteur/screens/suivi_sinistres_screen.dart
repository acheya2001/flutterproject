import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';

/// 📊 Écran de suivi des sinistres pour conducteurs
class SuiviSinistresScreen extends StatefulWidget {
  const SuiviSinistresScreen({Key? key}) : super(key: key);

  @override
  State<SuiviSinistresScreen> createState() => _SuiviSinistresScreenState();
}

class _SuiviSinistresScreenState extends State<SuiviSinistresScreen> {
  List<Map<String, dynamic>> _sinistres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSinistres();
  }

  /// 📋 Charger les sinistres du conducteur
  Future<void> _loadSinistres() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Charger les sinistres du conducteur
      final sinistresQuery = await FirebaseFirestore.instance
          .collection('sinistres')
          .where('conducteurId', isEqualTo: user.uid)
          .orderBy('dateCreation', descending: true)
          .get();

      final sinistres = <Map<String, dynamic>>[];

      for (final doc in sinistresQuery.docs) {
        final sinistreData = doc.data();
        sinistreData['id'] = doc.id;

        // Charger les informations de mission si expert assigné
        if (sinistreData['expertId'] != null) {
          try {
            final missionQuery = await FirebaseFirestore.instance
                .collection('missions_expertise')
                .where('sinistreId', isEqualTo: doc.id)
                .where('expertId', isEqualTo: sinistreData['expertId'])
                .limit(1)
                .get();

            if (missionQuery.docs.isNotEmpty) {
              sinistreData['missionInfo'] = missionQuery.docs.first.data();
              sinistreData['missionInfo']['id'] = missionQuery.docs.first.id;
            }
          } catch (e) {
            debugPrint('[SUIVI_SINISTRES] ❌ Erreur chargement mission: $e');
          }
        }

        sinistres.add(sinistreData);
      }

      setState(() => _sinistres = sinistres);
    } catch (e) {
      debugPrint('[SUIVI_SINISTRES] ❌ Erreur chargement sinistres: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Suivi de mes Sinistres'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSinistres,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sinistres.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _sinistres.length,
                  itemBuilder: (context, index) {
                    return _buildSinistreCard(_sinistres[index]);
                  },
                ),
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 16),
          Text(
            'Aucun sinistre déclaré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vos sinistres déclarés apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Carte de sinistre
  Widget _buildSinistreCard(Map<String, dynamic> sinistre) {
    final statut = sinistre['statut'] ?? 'ouvert';
    final expertId = sinistre['expertId'];
    final missionInfo = sinistre['missionInfo'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro et statut
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sinistre['numeroSinistre'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(sinistre['dateAccident']),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatutColor(statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatutText(statut),
                    style: TextStyle(
                      color: _getStatutColor(statut),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoRow('Type d\'accident', sinistre['typeAccident'] ?? 'N/A'),
            _buildInfoRow('Lieu', sinistre['lieuAccident'] ?? 'N/A'),
            _buildInfoRow('Gouvernorat', sinistre['gouvernorat'] ?? 'N/A'),

            // Timeline du sinistre
            const SizedBox(height: 20),
            _buildTimeline(sinistre),

            // Informations expert si assigné
            if (expertId != null) ...[
              const SizedBox(height: 20),
              _buildExpertInfo(sinistre),
            ],

            // Actions
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showSinistreDetails(sinistre),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir détails'),
                  ),
                ),
                if (statut == 'ouvert' || statut == 'en_attente_expertise') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _contactAgent(sinistre),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Contacter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Timeline du sinistre
  Widget _buildTimeline(Map<String, dynamic> sinistre) {
    final statut = sinistre['statut'] ?? 'ouvert';
    final steps = _getTimelineSteps(statut);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'État d\'avancement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: step['completed'] ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: step['completed']
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: const Color(0xFFE5E7EB),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: step['completed'] ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                        ),
                      ),
                      if (step['date'] != null)
                        Text(
                          _formatDate(step['date']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  /// 🔧 Informations expert
  Widget _buildExpertInfo(Map<String, dynamic> sinistre) {
    final missionInfo = sinistre['missionInfo'];
    final expertInfo = missionInfo?['expertInfo'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.engineering,
                color: Color(0xFF667EEA),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Expert assigné',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expertInfo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.engineering, size: 16, color: Colors.purple[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${expertInfo['prenom'] ?? ''} ${expertInfo['nom'] ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Code Expert', expertInfo['codeExpert'] ?? 'N/A'),
            _buildInfoRow('Téléphone', expertInfo['telephone'] ?? 'N/A'),
            if (missionInfo != null) ...[
              _buildInfoRow('Statut mission', _getMissionStatusText(missionInfo['statut'])),
              if (missionInfo['dateEcheance'] != null)
                _buildInfoRow('Échéance', _formatDate(missionInfo['dateEcheance'])),
            ],
          ] else
            const Text(
              'Informations expert non disponibles',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  /// 📋 Obtenir les étapes de la timeline
  List<Map<String, dynamic>> _getTimelineSteps(String statut) {
    final steps = [
      {
        'title': 'Sinistre déclaré',
        'completed': true,
        'date': null, // Sera rempli avec la date de création
      },
      {
        'title': 'En attente d\'expertise',
        'completed': ['en_attente_expertise', 'expertise_assignee', 'expertise_terminee', 'clos'].contains(statut),
        'date': null,
      },
      {
        'title': 'Expert assigné',
        'completed': ['expertise_assignee', 'expertise_terminee', 'clos'].contains(statut),
        'date': null,
      },
      {
        'title': 'Expertise terminée',
        'completed': ['expertise_terminee', 'clos'].contains(statut),
        'date': null,
      },
      {
        'title': 'Dossier clos',
        'completed': statut == 'clos',
        'date': null,
      },
    ];

    return steps;
  }

  /// 🎨 Obtenir la couleur du statut
  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'ouvert':
        return Colors.blue;
      case 'en_attente_expertise':
        return Colors.orange;
      case 'expertise_assignee':
        return Colors.purple;
      case 'expertise_terminee':
        return Colors.green;
      case 'clos':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 📝 Obtenir le texte du statut
  String _getStatutText(String statut) {
    switch (statut) {
      case 'ouvert':
        return 'Ouvert';
      case 'en_attente_expertise':
        return 'En attente';
      case 'expertise_assignee':
        return 'Expert assigné';
      case 'expertise_terminee':
        return 'Expertise terminée';
      case 'clos':
        return 'Clos';
      default:
        return 'Inconnu';
    }
  }

  /// 📝 Obtenir le texte du statut de mission
  String _getMissionStatusText(String? statut) {
    switch (statut) {
      case 'assignee':
        return 'Assignée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }

  /// 📅 Formater la date
  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// 👁️ Afficher les détails du sinistre
  void _showSinistreDetails(Map<String, dynamic> sinistre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails ${sinistre['numeroSinistre'] ?? 'N/A'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Numéro', sinistre['numeroSinistre'] ?? 'N/A'),
              _buildDetailRow('Date accident', _formatDate(sinistre['dateAccident'])),
              _buildDetailRow('Heure', sinistre['heureAccident'] ?? 'N/A'),
              _buildDetailRow('Type', sinistre['typeAccident'] ?? 'N/A'),
              _buildDetailRow('Lieu', sinistre['lieuAccident'] ?? 'N/A'),
              _buildDetailRow('Gouvernorat', sinistre['gouvernorat'] ?? 'N/A'),
              _buildDetailRow('Statut', _getStatutText(sinistre['statut'] ?? 'ouvert')),
              if (sinistre['description'] != null)
                _buildDetailRow('Description', sinistre['description']),
              if (sinistre['degatsEstimes'] != null)
                _buildDetailRow('Dégâts estimés', '${sinistre['degatsEstimes']} DT'),
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

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 📞 Contacter l'agent
  void _contactAgent(Map<String, dynamic> sinistre) {
    // TODO: Implémenter la fonctionnalité de contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de contact - À implémenter'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
