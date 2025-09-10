import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/agent_assignment_ai_service.dart';

/// 📋 Écran de gestion des demandes pour Super Admin
class DemandesManagementScreen extends StatefulWidget {
  const DemandesManagementScreen({Key? key}) : super(key: key);

  @override
  State<DemandesManagementScreen> createState() => _DemandesManagementScreenState();
}

class _DemandesManagementScreenState extends State<DemandesManagementScreen> {
  String _selectedFilter = 'en_attente';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gestion des Demandes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('en_attente', 'En Attente', Colors.orange),
                      _buildFilterChip('approuvee', 'Approuvées', Colors.green),
                      _buildFilterChip('affectee', 'Affectées', Colors.blue),
                      _buildFilterChip('rejetee', 'Rejetées', Colors.red),
                      _buildFilterChip('contrat_valide', 'Validées', Colors.purple),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des demandes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildDemandesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final demandes = snapshot.data?.docs ?? [];

                if (demandes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune demande ${_selectedFilter.replaceAll('_', ' ')}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: demandes.length,
                  itemBuilder: (context, index) {
                    final doc = demandes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildDemandeCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildDemandesStream() {
    return FirebaseFirestore.instance
        .collection('demandes_contrats')
        .where('statut', isEqualTo: _selectedFilter)
        .orderBy('dateCreation', descending: true)
        .snapshots();
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (mounted) setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color),
    );
  }

  Widget _buildDemandeCard(String id, Map<String, dynamic> data) {
    final dateCreation = data['dateCreation'] as Timestamp?;
    final dateStr = dateCreation?.toDate().toString().substring(0, 16) ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Demande ${data['numero'] ?? id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['statut']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(data['statut']),
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
            
            // Informations conducteur
            _buildInfoRow(Icons.person, 'Conducteur', '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'),
            _buildInfoRow(Icons.email, 'Email', data['email'] ?? ''),
            _buildInfoRow(Icons.phone, 'Téléphone', data['telephone'] ?? ''),
            _buildInfoRow(Icons.credit_card, 'CIN', data['cin'] ?? ''),
            
            const SizedBox(height: 8),
            
            // Informations véhicule
            _buildInfoRow(Icons.directions_car, 'Véhicule', '${data['marque'] ?? ''} ${data['modele'] ?? ''}'),
            _buildInfoRow(Icons.calendar_today, 'Année', data['annee']?.toString() ?? ''),
            _buildInfoRow(Icons.confirmation_number, 'Immatriculation', data['immatriculation'] ?? ''),
            
            const SizedBox(height: 8),
            
            // Informations agence
            _buildInfoRow(Icons.business, 'Agence', data['agenceNom'] ?? data['agenceId'] ?? ''),
            _buildInfoRow(Icons.location_city, 'Adresse', data['adresse'] ?? ''),
            _buildInfoRow(Icons.access_time, 'Date création', dateStr),

            // Agent assigné (si applicable)
            if (data['agentNom'] != null)
              _buildInfoRow(Icons.person_pin, 'Agent assigné', data['agentNom']),

            // Motif de rejet (si applicable)
            if (data['motifRejet'] != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motif de rejet: ${data['motifRejet']}',
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Actions
            if (data['statut'] == 'en_attente')
              Container(
                margin: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _approuverDemande(id, data),
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(_isLoading ? 'Traitement...' : 'Approuver avec IA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _rejeterDemande(id, data),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'approuvee':
      case 'affectee':
        return Colors.blue;
      case 'en_cours':
        return Colors.purple;
      case 'contrat_valide':
        return Colors.green;
      case 'rejetee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'approuvee':
        return 'Approuvée';
      case 'affectee':
        return 'Affectée';
      case 'en_cours':
        return 'En cours';
      case 'contrat_valide':
        return 'Validée';
      case 'rejetee':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  /// 🤖 Approuver une demande avec affectation IA
  Future<void> _approuverDemande(String demandeId, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    try {
      // 1. Utiliser l'IA pour trouver le meilleur agent
      final aiResult = await AgentAssignmentAIService.findBestAgent(
        agenceId: data['agenceId'],
        demandeData: data,
      );

      if (!aiResult['success']) {
        throw Exception(aiResult['error']);
      }

      final bestAgent = aiResult['bestAgent'];
      final recommendation = aiResult['recommendation'];

      // 2. Afficher la recommandation à l'admin
      final confirmed = await _showAIRecommendationDialog(
        bestAgent,
        recommendation,
        aiResult['allScores'],
      );

      if (!confirmed) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Approuver et affecter
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'affectee',
        'agentId': bestAgent['id'],
        'agentNom': '${bestAgent['prenom']} ${bestAgent['nom']}',
        'agentEmail': bestAgent['email'],
        'dateAffectation': FieldValue.serverTimestamp(),
        'approuvePar': 'Super Admin',
        'dateApprobation': FieldValue.serverTimestamp(),
        'affectationIA': true,
        'scoreIA': aiResult['score'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Demande approuvée et affectée à ${bestAgent['prenom']} ${bestAgent['nom']}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 💬 Afficher le dialogue de recommandation IA
  Future<bool> _showAIRecommendationDialog(
    Map<String, dynamic> bestAgent,
    String recommendation,
    List<Map<String, dynamic>> allScores,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue),
            SizedBox(width: 8),
            Text('🤖 Recommandation IA'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(recommendation),
              const SizedBox(height: 16),
              const Text(
                'Tous les agents:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...allScores.take(3).map((agentScore) {
                final agent = agentScore['agent'];
                final score = agentScore['score'];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: agentScore == allScores.first 
                          ? Colors.green 
                          : Colors.grey,
                      child: Text(
                        '${agent['prenom'][0]}${agent['nom'][0]}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('${agent['prenom']} ${agent['nom']}'),
                    subtitle: Text(
                      'Score: ${score['total'].toStringAsFixed(2)} | '
                      'Charge: ${score['details']['chargeActuelle']} contrats',
                    ),
                    trailing: agentScore == allScores.first
                        ? const Icon(Icons.star, color: Colors.gold)
                        : null,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// ❌ Rejeter une demande
  Future<void> _rejeterDemande(String demandeId, Map<String, dynamic> data) async {
    final motif = await _showRejetDialog();
    if (motif == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(demandeId)
          .update({
        'statut': 'rejetee',
        'motifRejet': motif,
        'rejetePar': 'Super Admin',
        'dateRejet': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Demande rejetée'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 💬 Dialogue pour saisir le motif de rejet
  Future<String?> _showRejetDialog() async {
    final controller = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif de rejet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Saisissez le motif de rejet...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}

