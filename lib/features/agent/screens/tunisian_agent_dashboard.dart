import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/tunisian_payment_service.dart';
import 'tunisian_contract_creation_screen.dart';

/// 🏢 Dashboard agent tunisien moderne
class TunisianAgentDashboard extends StatefulWidget {
  final String agentId;
  final String agenceId;

  const TunisianAgentDashboard({
    Key? key,
    required this.agentId,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<TunisianAgentDashboard> createState() => _TunisianAgentDashboardState();
}

class _TunisianAgentDashboardState extends State<TunisianAgentDashboard> {
  Map<String, dynamic>? _agentInfo;
  Map<String, dynamic>? _agenceInfo;
  Map<String, dynamic>? _statistiques;
  List<Map<String, dynamic>> _contratsARenouveler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildDashboardContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 📱 AppBar moderne
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Agent',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_agenceInfo != null)
            Text(
              _agenceInfo!['nom'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showNotifications(),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => _showProfile(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  /// 📊 Contenu principal du dashboard
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message de bienvenue
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          
          // Statistiques rapides
          _buildQuickStats(),
          const SizedBox(height: 20),
          
          // Actions principales
          _buildMainActions(),
          const SizedBox(height: 20),
          
          // Contrats à renouveler
          _buildRenewalSection(),
          const SizedBox(height: 20),
          
          // Activité récente
          _buildRecentActivity(),
        ],
      ),
    );
  }

  /// 👋 Carte de bienvenue
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_agentInfo != null)
                      Text(
                        '${_agentInfo!['prenom']} ${_agentInfo!['nom']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Prêt à créer de nouveaux contrats d\'assurance ?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 📈 Statistiques rapides
  Widget _buildQuickStats() {
    if (_statistiques == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Aperçu Rapide',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Contrats Actifs',
                '${_statistiques!['contratsActifs'] ?? 0}',
                Icons.assignment_turned_in,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'À Renouveler',
                '${_contratsARenouveler.length}',
                Icons.refresh,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'CA du Mois',
                '${_statistiques!['chiffreAffaires'] ?? 0} TND',
                Icons.trending_up,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Taux Renouvellement',
                '${_statistiques!['tauxRenouvellement'] ?? 0}%',
                Icons.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions principales
  Widget _buildMainActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Actions Principales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              'Nouveau Contrat',
              'Créer un contrat d\'assurance',
              Icons.add_circle_outline,
              Colors.blue,
              () => _createNewContract(),
            ),
            _buildActionCard(
              'Mes Contrats',
              'Gérer les contrats existants',
              Icons.assignment_outlined,
              Colors.green,
              () => _showContracts(),
            ),
            _buildActionCard(
              'Renouvellements',
              'Traiter les renouvellements',
              Icons.refresh_outlined,
              Colors.orange,
              () => _showRenewals(),
            ),
            _buildActionCard(
              'Encaissements',
              'Gérer les paiements',
              Icons.payment_outlined,
              Colors.purple,
              () => _showPayments(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 Section renouvellements
  Widget _buildRenewalSection() {
    if (_contratsARenouveler.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🔄 Contrats à Renouveler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showRenewals(),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _contratsARenouveler.take(5).length,
            itemBuilder: (context, index) {
              final contrat = _contratsARenouveler[index];
              return _buildRenewalCard(contrat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRenewalCard(Map<String, dynamic> contrat) {
    Color urgenceColor = _getUrgenceColor(contrat['urgence']);
    
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: urgenceColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${contrat['joursRestants']} jours',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: urgenceColor,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.warning_amber, color: urgenceColor, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contrat['numeroContrat'] ?? '',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${contrat['primeAnnuelle']} TND',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Activité récente
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📱 Activité Récente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Contrat créé',
                'CTR-2024-001234',
                '2 heures',
                Icons.add_circle,
                Colors.green,
              ),
              _buildActivityItem(
                'Paiement encaissé',
                '450 TND',
                '4 heures',
                Icons.payment,
                Colors.blue,
              ),
              _buildActivityItem(
                'Renouvellement traité',
                'CTR-2023-005678',
                '1 jour',
                Icons.refresh,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔧 Méthodes utilitaires
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _createNewContract,
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nouveau Contrat'),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  Color _getUrgenceColor(String urgence) {
    switch (urgence) {
      case 'critique': return Colors.red;
      case 'elevee': return Colors.orange;
      case 'normale': return Colors.blue;
      default: return Colors.grey;
    }
  }

  /// 📊 Charger les données du dashboard
  Future<void> _loadDashboardData() async {
    try {
      // Charger les informations de l'agent et de l'agence
      await Future.wait([
        _loadAgentInfo(),
        _loadAgenceInfo(),
        _loadStatistiques(),
        _loadContratsARenouveler(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAgentInfo() async {
    // TODO: Charger depuis Firestore
  }

  Future<void> _loadAgenceInfo() async {
    // TODO: Charger depuis Firestore
  }

  Future<void> _loadStatistiques() async {
    _statistiques = await TunisianRenewalService.getStatistiquesRenouvellement(
      agenceId: widget.agenceId,
    );
  }

  Future<void> _loadContratsARenouveler() async {
    _contratsARenouveler = await TunisianRenewalService.getContratsARenouveler(
      agenceId: widget.agenceId,
      joursAvance: 30,
    );
  }

  /// 🎯 Actions
  void _createNewContract() {
    // TODO: Naviguer vers la sélection de véhicule puis création de contrat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TunisianContractCreationScreen(
          vehiculeId: 'demo_vehicle_id',
          vehiculeData: {
            'numeroImmatriculation': '123 TUN 456',
            'marque': 'Toyota',
            'modele': 'Corolla',
            'annee': 2020,
            'puissanceFiscale': 6,
            'typeVehicule': 'voiture',
          },
          agentId: widget.agentId,
          agenceId: widget.agenceId,
        ),
      ),
    );
  }

  void _showContracts() {
    // TODO: Implémenter
  }

  void _showRenewals() {
    // TODO: Implémenter
  }

  void _showPayments() {
    // TODO: Implémenter
  }

  void _showNotifications() {
    // TODO: Implémenter
  }

  void _showProfile() {
    // TODO: Implémenter
  }
}
