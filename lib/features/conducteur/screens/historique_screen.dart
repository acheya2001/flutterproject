import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📚 Historique'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Contrats'),
            Tab(icon: Icon(Icons.warning), text: 'Sinistres'),
            Tab(icon: Icon(Icons.payment), text: 'Paiements'),
          ],
        ),
      ),
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContratsTab(),
                _buildSinistresTab(),
                _buildPaiementsTab(),
              ],
            ),
    );
  }

  Widget _buildContratsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurId', isEqualTo: _currentUserId)
          .orderBy('dateCreation', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contrats = snapshot.data?.docs ?? [];

        if (contrats.isEmpty) {
          return _buildEmptyState(
            icon: Icons.description_outlined,
            title: 'Aucun contrat',
            subtitle: 'Votre historique de contrats apparaîtra ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contrats.length,
          itemBuilder: (context, index) {
            final contrat = contrats[index];
            final data = contrat.data() as Map<String, dynamic>;
            return _buildContratCard(data);
          },
        );
      },
    );
  }

  Widget _buildSinistresTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sinistres')
          .where('conducteurId', isEqualTo: _currentUserId)
          .orderBy('dateDeclaration', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sinistres = snapshot.data?.docs ?? [];

        if (sinistres.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shield_outlined,
            title: 'Aucun sinistre',
            subtitle: 'Tant mieux ! Aucun sinistre déclaré',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sinistres.length,
          itemBuilder: (context, index) {
            final sinistre = sinistres[index];
            final data = sinistre.data() as Map<String, dynamic>;
            return _buildSinistreCard(data);
          },
        );
      },
    );
  }

  Widget _buildPaiementsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('echeances')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('statut', isEqualTo: 'payee')
          .orderBy('datePaiement', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final paiements = snapshot.data?.docs ?? [];

        if (paiements.isEmpty) {
          return _buildEmptyState(
            icon: Icons.payment_outlined,
            title: 'Aucun paiement',
            subtitle: 'Votre historique de paiements apparaîtra ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: paiements.length,
          itemBuilder: (context, index) {
            final paiement = paiements[index];
            final data = paiement.data() as Map<String, dynamic>;
            return _buildPaiementCard(data);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContratCard(Map<String, dynamic> data) {
    final numeroContrat = data['numeroContrat'] ?? 'N/A';
    final vehicule = data['vehicule'] as Map<String, dynamic>? ?? {};
    final statut = data['statut'] ?? 'inactif';
    final dateDebut = data['dateDebut']?.toDate();
    final dateFin = data['dateFin']?.toDate();
    final formuleLabel = data['formuleAssuranceLabel'] ?? 'N/A';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (statut) {
      case 'actif':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Actif';
        break;
      case 'expire':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Expiré';
        break;
      case 'suspendu':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle;
        statusText = 'Suspendu';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inactif';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contrat $numeroContrat',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              '🚗 ${vehicule['marque'] ?? ''} ${vehicule['modele'] ?? ''} - ${vehicule['immatriculation'] ?? ''}',
              style: const TextStyle(fontSize: 14),
            ),
            
            Text(
              '🛡️ $formuleLabel',
              style: const TextStyle(fontSize: 14),
            ),
            
            if (dateDebut != null && dateFin != null)
              Text(
                '📅 Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinistreCard(Map<String, dynamic> data) {
    final numeroSinistre = data['numeroSinistre'] ?? 'N/A';
    final typeSinistre = data['typeSinistre'] ?? 'N/A';
    final statut = data['statut'] ?? 'en_cours';
    final dateDeclaration = data['dateDeclaration']?.toDate();
    final montantEstime = data['montantEstime'] ?? 0.0;

    Color statusColor;
    IconData statusIcon;

    switch (statut) {
      case 'clos':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'en_cours':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'rejete':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sinistre $numeroSinistre',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        statut.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (montantEstime > 0)
                  Text(
                    '${montantEstime.toStringAsFixed(0)} DT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              '⚠️ $typeSinistre',
              style: const TextStyle(fontSize: 14),
            ),
            
            if (dateDeclaration != null)
              Text(
                '📅 Déclaré le ${_formatDate(dateDeclaration)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaiementCard(Map<String, dynamic> data) {
    final numeroEcheance = data['numeroEcheance'] ?? 1;
    final montant = data['montant'] ?? 0.0;
    final datePaiement = data['datePaiement']?.toDate();
    final contratId = data['contratId'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payment, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Échéance n°$numeroEcheance',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (datePaiement != null)
                    Text(
                      'Payé le ${_formatDate(datePaiement)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${montant.toStringAsFixed(0)} DT',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
