import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/conducteur_constat_service.dart';

/// 📱 Écran de suivi des constats pour le conducteur
class SuiviConstatsScreen extends StatefulWidget {
  final Map<String, dynamic> conducteurData;

  const SuiviConstatsScreen({
    super.key,
    required this.conducteurData,
  });

  @override
  State<SuiviConstatsScreen> createState() => _SuiviConstatsScreenState();
}

class _SuiviConstatsScreenState extends State<SuiviConstatsScreen> {
  List<Map<String, dynamic>> _constats = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConstats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📋 Charger les constats du conducteur
  Future<void> _loadConstats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final constats = await ConducteurConstatService.getConstatsForConducteur(
        conducteurId: widget.conducteurData['uid'] ?? widget.conducteurData['id'] ?? '',
      );

      final stats = await ConducteurConstatService.getConstatStats(
        conducteurId: widget.conducteurData['uid'] ?? widget.conducteurData['id'] ?? '',
      );

      setState(() {
        _constats = constats;
        _stats = stats;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('[SUIVI_CONSTATS] ❌ Erreur chargement constats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🔍 Rechercher un constat par code
  Future<void> _searchConstat() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez saisir un code de constat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final constat = await ConducteurConstatService.getConstatByCode(
        codeConstat: code,
        conducteurId: widget.conducteurData['uid'] ?? widget.conducteurData['id'],
      );

      if (constat != null) {
        _showConstatDetails(constat);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Constat non trouvé ou non autorisé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur de recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de mes Constats'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConstats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de recherche
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Rechercher par code de constat...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _searchConstat(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _searchConstat,
                        child: const Text('Rechercher'),
                      ),
                    ],
                  ),
                ),

                // Statistiques
                if (_stats.isNotEmpty) _buildStatsSection(),

                // Liste des constats
                Expanded(
                  child: _constats.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucun constat trouvé',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _constats.length,
                          itemBuilder: (context, index) {
                            final constat = _constats[index];
                            return _buildConstatCard(constat);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// 📊 Section des statistiques
  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mes Statistiques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('Total', _stats['total'], Colors.blue)),
              Expanded(child: _buildStatItem('En attente', _stats['en_attente'], Colors.orange)),
              Expanded(child: _buildStatItem('Expert assigné', _stats['expert_assigne'], Colors.purple)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStatItem('En expertise', _stats['en_expertise'], Colors.indigo)),
              Expanded(child: _buildStatItem('Terminé', _stats['termine'], Colors.green)),
              const Expanded(child: SizedBox()), // Espace vide
            ],
          ),
        ],
      ),
    );
  }

  /// 📈 Item de statistique
  Widget _buildStatItem(String label, int value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📄 Carte de constat
  Widget _buildConstatCard(Map<String, dynamic> constat) {
    final statut = constat['statut'] ?? 'finalise';
    final statutFormate = ConducteurConstatService.getStatutFormate(statut);
    final couleurStatut = _getStatutColor(statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showConstatDetails(constat),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec code et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Constat ${constat['codeConstat'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: couleurStatut,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statutFormate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations du constat
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${ConducteurConstatService.formatDate(constat['dateCreation'])}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lieu: ${constat['lieuAccident'] ?? 'Non spécifié'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),

              // Informations expert si assigné
              if (constat['expertAssigne'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.engineering, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expert: ${constat['expertAssigne']['nom'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Obtenir la couleur du statut
  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'finalise':
        return Colors.orange;
      case 'expert_assigne':
        return Colors.blue;
      case 'en_expertise':
        return Colors.purple;
      case 'expertise_terminee':
        return Colors.green;
      case 'cloture':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 📋 Afficher les détails du constat
  void _showConstatDetails(Map<String, dynamic> constat) {
    showDialog(
      context: context,
      builder: (context) => _ConstatDetailsDialog(constat: constat),
    );
  }
}

/// 📋 Dialogue des détails du constat
class _ConstatDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> constat;

  const _ConstatDetailsDialog({required this.constat});

  @override
  Widget build(BuildContext context) {
    final statut = constat['statut'] ?? 'finalise';
    final statutFormate = ConducteurConstatService.getStatutFormate(statut);

    return AlertDialog(
      title: Text('Constat ${constat['codeConstat'] ?? 'N/A'}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Statut
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatutColor(statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getStatutColor(statut).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_getStatutIcon(statut), color: _getStatutColor(statut)),
                    const SizedBox(width: 8),
                    Text(
                      'Statut: $statutFormate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatutColor(statut),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Informations générales
              _buildDetailRow('Date de création', ConducteurConstatService.formatDate(constat['dateCreation'])),
              _buildDetailRow('Lieu de l\'accident', constat['lieuAccident'] ?? 'Non spécifié'),
              _buildDetailRow('Type d\'accident', constat['typeAccident'] ?? 'Non spécifié'),
              _buildDetailRow('Numéro de contrat', constat['numeroContrat'] ?? 'N/A'),
              _buildDetailRow('Numéro de police', constat['numeroPolice'] ?? 'N/A'),

              // Informations expert si assigné
              if (constat['expertAssigne'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Expert Assigné',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Nom', constat['expertAssigne']['nom'] ?? 'N/A'),
                      _buildDetailRow('Code expert', constat['expertAssigne']['codeExpert'] ?? 'N/A'),
                      _buildDetailRow('Téléphone', constat['expertAssigne']['telephone'] ?? 'N/A'),
                      _buildDetailRow('Email', constat['expertAssigne']['email'] ?? 'N/A'),
                      if (constat['dateAssignationExpert'] != null)
                        _buildDetailRow('Date d\'assignation', ConducteurConstatService.formatDate(constat['dateAssignationExpert'])),
                      if (constat['delaiInterventionHeures'] != null)
                        _buildDetailRow('Délai d\'intervention', '${constat['delaiInterventionHeures']} heures'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'finalise':
        return Colors.orange;
      case 'expert_assigne':
        return Colors.blue;
      case 'en_expertise':
        return Colors.purple;
      case 'expertise_terminee':
        return Colors.green;
      case 'cloture':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'finalise':
        return Icons.hourglass_empty;
      case 'expert_assigne':
        return Icons.engineering;
      case 'en_expertise':
        return Icons.search;
      case 'expertise_terminee':
        return Icons.check_circle;
      case 'cloture':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }
}
