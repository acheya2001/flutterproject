import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/widgets/custom_app_bar.dart';

/// 🏢 Écran Admin Agence - Constats reçus automatiquement
class ConstatsRecusScreen extends StatefulWidget {
  const ConstatsRecusScreen({super.key});

  @override
  State<ConstatsRecusScreen> createState() => _ConstatsRecusScreenState();
}

class _ConstatsRecusScreenState extends State<ConstatsRecusScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _agenceId;
  String _filtreStatut = 'tous';
  String _filtrePriorite = 'tous';
  
  @override
  void initState() {
    super.initState();
    _chargerAgenceId();
  }

  Future<void> _chargerAgenceId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _agenceId = userDoc.data()?['agenceId'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Constats Reçus',
        subtitle: 'Gestion des déclarations d\'accident',
      ),
      body: _agenceId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltres(),
                _buildStatistiques(),
                Expanded(child: _buildListeConstats()),
              ],
            ),
    );
  }

  Widget _buildFiltres() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filtreStatut,
              decoration: const InputDecoration(
                labelText: 'Statut',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'tous', child: Text('Tous les statuts')),
                DropdownMenuItem(value: 'nouveau', child: Text('Nouveaux')),
                DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem(value: 'expert_assigne', child: Text('Expert assigné')),
                DropdownMenuItem(value: 'termine', child: Text('Terminés')),
              ],
              onChanged: (value) {
                setState(() {
                  _filtreStatut = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filtrePriorite,
              decoration: const InputDecoration(
                labelText: 'Priorité',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'tous', child: Text('Toutes priorités')),
                DropdownMenuItem(value: 'haute', child: Text('Haute')),
                DropdownMenuItem(value: 'moyenne', child: Text('Moyenne')),
                DropdownMenuItem(value: 'normale', child: Text('Normale')),
              ],
              onChanged: (value) {
                setState(() {
                  _filtrePriorite = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiques() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('constats_recus')
          .where('agenceId', isEqualTo: _agenceId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data!.docs;
        final nouveaux = docs.where((d) => (d.data() as Map<String, dynamic>)['statut'] == 'nouveau').length;
        final enCours = docs.where((d) => (d.data() as Map<String, dynamic>)['statut'] == 'en_cours').length;
        final termines = docs.where((d) => (d.data() as Map<String, dynamic>)['statut'] == 'termine').length;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard('Nouveaux', nouveaux, Colors.red),
              const SizedBox(width: 16),
              _buildStatCard('En cours', enCours, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard('Terminés', termines, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeConstats() {
    Query query = _firestore
        .collection('constats_recus')
        .where('agenceId', isEqualTo: _agenceId)
        .orderBy('dateReception', descending: true);

    // Appliquer les filtres
    if (_filtreStatut != 'tous') {
      query = query.where('statut', isEqualTo: _filtreStatut);
    }
    if (_filtrePriorite != 'tous') {
      query = query.where('priorite', isEqualTo: _filtrePriorite);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun constat reçu',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildConstatCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildConstatCard(String docId, Map<String, dynamic> data) {
    final statut = data['statut'] as String;
    final priorite = data['priorite'] as String;
    final dateReception = (data['dateReception'] as Timestamp).toDate();
    final dateAccident = (data['dateAccident'] as Timestamp).toDate();

    Color statutColor = _getStatutColor(statut);
    Color prioriteColor = _getPrioriteColor(priorite);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: statutColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _ouvrirDetailConstat(docId, data),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec code et badges
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Constat ${data['codePublic']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Véhicule ${data['vehiculeRole']} - Police: ${data['numeroPolice']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: prioriteColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        priorite.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: prioriteColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatutText(statut),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statutColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations détaillées
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Accident: ${_formatDate(dateAccident)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Reçu: ${_formatDate(dateReception)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                if (data['expertAssigne'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Expert: ${data['expertAssigne']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Actions rapides
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _telechargerPDF(data['pdfUrl']),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('PDF', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _assignerExpert(docId),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Expert', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'nouveau': return Colors.red;
      case 'en_cours': return Colors.orange;
      case 'expert_assigne': return Colors.blue;
      case 'termine': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getPrioriteColor(String priorite) {
    switch (priorite) {
      case 'haute': return Colors.red;
      case 'moyenne': return Colors.orange;
      case 'normale': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatutText(String statut) {
    switch (statut) {
      case 'nouveau': return 'NOUVEAU';
      case 'en_cours': return 'EN COURS';
      case 'expert_assigne': return 'EXPERT';
      case 'termine': return 'TERMINÉ';
      default: return 'INCONNU';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _ouvrirDetailConstat(String docId, Map<String, dynamic> data) {
    // TODO: Naviguer vers l'écran de détail du constat
    Navigator.pushNamed(
      context,
      '/admin/constat-detail',
      arguments: {'docId': docId, 'data': data},
    );
  }

  void _telechargerPDF(String pdfUrl) {
    // TODO: Implémenter le téléchargement du PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement du PDF...')),
    );
  }

  void _assignerExpert(String docId) {
    // TODO: Ouvrir dialog pour assigner un expert
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assigner un Expert'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
