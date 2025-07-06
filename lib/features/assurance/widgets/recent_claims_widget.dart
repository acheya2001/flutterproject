import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 📋 Widget pour afficher les constats récents
class RecentClaimsWidget extends StatefulWidget {
  final String compagnieId;

  const RecentClaimsWidget({
    super.key,
    required this.compagnieId,
  });

  @override
  State<RecentClaimsWidget> createState() => _RecentClaimsWidgetState();
}

class _RecentClaimsWidgetState extends State<RecentClaimsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ConstatRecent> _constats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentClaims();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
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
              children: [
                const Icon(Icons.assignment, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Constats Récents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showAllClaims,
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_constats.isEmpty)
              _buildEmptyState()
            else
              _buildClaimsList(),
          ],
        ),
      ),
    );
  }

  /// 📋 Liste des constats
  Widget _buildClaimsList() {
    return Column(
      children: _constats.take(5).map((constat) => _buildClaimItem(constat)).toList(),
    );
  }

  /// 📄 Item de constat
  Widget _buildClaimItem(ConstatRecent constat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(constat.statut).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(constat.statut),
              color: _getStatusColor(constat.statut),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Constat #${constat.numero}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  constat.lieu,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(constat.dateAccident),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Montant et statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${constat.montantEstime} TND',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(constat.statut).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(constat.statut),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(constat.statut),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun constat récent',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les nouveaux constats apparaîtront ici',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Charger les constats récents
  Future<void> _loadRecentClaims() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les constats récents de la compagnie
      final snapshot = await _firestore
          .collection('constats')
          .where('assureur_responsable', isEqualTo: widget.compagnieId)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      final constats = snapshot.docs.map((doc) {
        final data = doc.data();
        return ConstatRecent(
          id: doc.id,
          numero: doc.id.substring(0, 8).toUpperCase(),
          lieu: data['lieu'] ?? 'Lieu non spécifié',
          dateAccident: (data['date_accident'] as Timestamp?)?.toDate() ?? DateTime.now(),
          montantEstime: data['montant_estime'] ?? 0,
          statut: data['statut'] ?? 'en_attente',
        );
      }).toList();

      setState(() {
        _constats = constats;
        _isLoading = false;
      });
    } catch (e) {
      // Si pas de données, générer des exemples
      setState(() {
        _constats = _generateSampleClaims();
        _isLoading = false;
      });
      debugPrint('Erreur lors du chargement des constats: $e');
    }
  }

  /// 🎲 Générer des constats d'exemple
  List<ConstatRecent> _generateSampleClaims() {
    final lieux = [
      'Avenue Habib Bourguiba, Tunis',
      'Autoroute A1, Sfax',
      'Rue de la République, Sousse',
      'Avenue Mohamed V, Nabeul',
      'Centre-ville, Bizerte',
    ];

    final statuts = ['en_attente', 'en_cours', 'valide', 'clos'];

    return List.generate(5, (index) {
      final now = DateTime.now();
      return ConstatRecent(
        id: 'CONST${(index + 1).toString().padLeft(3, '0')}',
        numero: 'C${DateTime.now().year}${(index + 1).toString().padLeft(4, '0')}',
        lieu: lieux[index % lieux.length],
        dateAccident: now.subtract(Duration(days: index + 1)),
        montantEstime: (index + 1) * 1500 + 500,
        statut: statuts[index % statuts.length],
      );
    });
  }

  /// 🎨 Couleur du statut
  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'valide':
        return Colors.green;
      case 'clos':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 🔧 Icône du statut
  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'en_attente':
        return Icons.schedule;
      case 'en_cours':
        return Icons.work;
      case 'valide':
        return Icons.check_circle;
      case 'clos':
        return Icons.archive;
      default:
        return Icons.help;
    }
  }

  /// 📝 Label du statut
  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'valide':
        return 'Validé';
      case 'clos':
        return 'Clos';
      default:
        return 'Inconnu';
    }
  }

  /// 📅 Formater la date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// 📋 Afficher tous les constats
  void _showAllClaims() {
    // TODO: Naviguer vers la liste complète des constats
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Navigation vers tous les constats'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// 📋 Modèle pour un constat récent
class ConstatRecent {
  final String id;
  final String numero;
  final String lieu;
  final DateTime dateAccident;
  final int montantEstime;
  final String statut;

  ConstatRecent({
    required this.id,
    required this.numero,
    required this.lieu,
    required this.dateAccident,
    required this.montantEstime,
    required this.statut,
  });
}
