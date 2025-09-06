import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/widgets/custom_app_bar.dart';
import '../../common/widgets/gradient_background.dart';

/// 📋 Écran pour l'admin agence - Gestion des sinistres reçus
class AgenceSinistresRecusScreen extends StatefulWidget {
  const AgenceSinistresRecusScreen({Key? key}) : super(key: key);

  @override
  State<AgenceSinistresRecusScreen> createState() => _AgenceSinistresRecusScreenState();
}

class _AgenceSinistresRecusScreenState extends State<AgenceSinistresRecusScreen> {
  String _selectedFilter = 'tous';
  String? _agenceId;

  @override
  void initState() {
    super.initState();
    _loadAgenceId();
  }

  Future<void> _loadAgenceId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _agenceId = userDoc.data()?['agenceId'];
          });
        }
      }
    } catch (e) {
      print('❌ Erreur chargement agenceId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Sinistres Reçus',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              _buildFilters(),
              Expanded(
                child: _agenceId == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildSinistresList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrer par statut',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('tous', 'Tous'),
              _buildFilterChip('nouveau', 'Nouveaux'),
              _buildFilterChip('en_cours', 'En cours'),
              _buildFilterChip('traite', 'Traités'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[600],
    );
  }

  Widget _buildSinistresList() {
    Query query = FirebaseFirestore.instance
        .collection('agences')
        .doc(_agenceId)
        .collection('sinistres_recus')
        .orderBy('dateReception', descending: true);

    if (_selectedFilter != 'tous') {
      query = query.where('statut', isEqualTo: _selectedFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sinistres = snapshot.data?.docs ?? [];

        if (sinistres.isEmpty) {
          return _buildEmptyWidget();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sinistres.length,
          itemBuilder: (context, index) {
            final doc = sinistres[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildSinistreCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildSinistreCard(String id, Map<String, dynamic> data) {
    final statut = data['statut'] ?? 'nouveau';
    final dateReception = (data['dateReception'] as Timestamp?)?.toDate();
    final sessionData = data['sessionData'] as Map<String, dynamic>? ?? {};
    final participantData = data['participantData'] as Map<String, dynamic>? ?? {};

    final statutColor = _getStatutColor(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statutColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statutColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSinistreDetails(id, data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session: ${sessionData['codePublic'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Conducteur: ${participantData['nom'] ?? 'Inconnu'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatutLabel(statut),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statutColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations de l'accident
                if (sessionData.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Reçu le ${_formatDate(dateReception)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sessionData['localisation']?['adresse'] ?? 'Lieu non spécifié',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    if (statut == 'nouveau') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _traiterSinistre(id, 'en_cours'),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Traiter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSinistreDetails(id, data),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
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
              'Aucun sinistre reçu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les sinistres envoyés par les conducteurs apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'nouveau':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'traite':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'nouveau':
        return 'Nouveau';
      case 'en_cours':
        return 'En cours';
      case 'traite':
        return 'Traité';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date inconnue';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _traiterSinistre(String sinistreId, String nouveauStatut) async {
    try {
      await FirebaseFirestore.instance
          .collection('agences')
          .doc(_agenceId)
          .collection('sinistres_recus')
          .doc(sinistreId)
          .update({
        'statut': nouveauStatut,
        'dateTraitement': FieldValue.serverTimestamp(),
        'traiteParUserId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut mis à jour avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _showSinistreDetails(String id, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du sinistre'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: $id'),
              const SizedBox(height: 8),
              Text('Statut: ${_getStatutLabel(data['statut'] ?? 'nouveau')}'),
              const SizedBox(height: 8),
              Text('Date réception: ${_formatDate((data['dateReception'] as Timestamp?)?.toDate())}'),
              const SizedBox(height: 16),
              const Text('Données de session:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['sessionData'].toString()),
              const SizedBox(height: 16),
              const Text('Données participant:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['participantData'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (data['statut'] == 'nouveau')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _traiterSinistre(id, 'en_cours');
              },
              child: const Text('Traiter'),
            ),
        ],
      ),
    );
  }
}
