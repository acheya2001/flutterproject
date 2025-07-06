import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assurance_data_model.dart';
import '../widgets/kpi_card_widget.dart';
import '../widgets/chart_widget.dart';
import '../widgets/recent_claims_widget.dart';
import '../widgets/quick_actions_widget.dart';

/// 🏠 Dashboard principal pour les assureurs
class AssureurDashboardScreen extends StatefulWidget {
  final String compagnieId;

  const AssureurDashboardScreen({
    super.key,
    required this.compagnieId,
  });

  @override
  State<AssureurDashboardScreen> createState() => _AssureurDashboardScreenState();
}

class _AssureurDashboardScreenState extends State<AssureurDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CompagnieAssurance? _compagnie;
  Map<String, dynamic> _kpis = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildDashboardContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 📱 AppBar personnalisée
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _compagnie?.nom ?? 'Dashboard Assureur',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Tableau de bord',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      backgroundColor: _getCompanyColor(),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _showNotifications,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Profil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Déconnexion'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Contenu du dashboard
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec informations compagnie
            _buildCompanyHeader(),
            
            const SizedBox(height: 20),
            
            // KPIs principaux
            _buildKPIsSection(),
            
            const SizedBox(height: 20),
            
            // Graphiques et analytics
            _buildChartsSection(),
            
            const SizedBox(height: 20),
            
            // Actions rapides et constats récents
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: QuickActionsWidget(
                    compagnieId: widget.compagnieId,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: RecentClaimsWidget(
                    compagnieId: widget.compagnieId,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🏢 En-tête compagnie
  Widget _buildCompanyHeader() {
    if (_compagnie == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getCompanyColor().withValues(alpha: 0.1),
            _getCompanyColor().withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getCompanyColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getCompanyColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _compagnie!.code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _compagnie!.nom,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getCompanyColor(),
                  ),
                ),
                Text(
                  _compagnie!.slogan,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_compagnie!.agences.length} agences',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.verified, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Agréée',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Section KPIs
  Widget _buildKPIsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Indicateurs Clés',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getCompanyColor(),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            KPICardWidget(
              title: 'Contrats Actifs',
              value: '${_kpis['contrats_actifs'] ?? 0}',
              icon: Icons.assignment,
              color: Colors.blue,
              trend: '+5.2%',
            ),
            KPICardWidget(
              title: 'Sinistres du Mois',
              value: '${_kpis['sinistres_mois'] ?? 0}',
              icon: Icons.warning,
              color: Colors.orange,
              trend: '-2.1%',
            ),
            KPICardWidget(
              title: 'Chiffre d\'Affaires',
              value: '${(_kpis['chiffre_affaires'] ?? 0) ~/ 1000}K TND',
              icon: Icons.monetization_on,
              color: Colors.green,
              trend: '+8.7%',
            ),
            KPICardWidget(
              title: 'Satisfaction',
              value: '${_kpis['satisfaction'] ?? 0}/5',
              icon: Icons.star,
              color: Colors.purple,
              trend: '+0.3',
            ),
          ],
        ),
      ],
    );
  }

  /// 📈 Section graphiques
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _getCompanyColor(),
          ),
        ),
        const SizedBox(height: 12),
        ChartWidget(
          compagnieId: widget.compagnieId,
          color: _getCompanyColor(),
        ),
      ],
    );
  }

  /// ❌ État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// ➕ Bouton d'action flottant
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showQuickActions,
      backgroundColor: _getCompanyColor(),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Nouveau'),
    );
  }

  /// 📊 Charger les données du dashboard
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les informations de la compagnie
      final compagnieDoc = await _firestore
          .collection('assureurs_compagnies')
          .doc(widget.compagnieId)
          .get();

      if (compagnieDoc.exists) {
        _compagnie = CompagnieAssurance.fromMap(
          compagnieDoc.data()!,
          compagnieDoc.id,
        );
      }

      // Charger les KPIs
      await _loadKPIs();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 📊 Charger les KPIs
  Future<void> _loadKPIs() async {
    try {
      // Compter les contrats actifs
      final contratsSnapshot = await _firestore
          .collection('vehicules_assures')
          .where('assureur_id', isEqualTo: widget.compagnieId)
          .where('statut', isEqualTo: 'actif')
          .count()
          .get();

      // Compter les sinistres du mois
      final debutMois = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final sinistresSnapshot = await _firestore
          .collection('constats')
          .where('assureur_responsable', isEqualTo: widget.compagnieId)
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(debutMois))
          .count()
          .get();

      setState(() {
        _kpis = {
          'contrats_actifs': contratsSnapshot.count,
          'sinistres_mois': sinistresSnapshot.count,
          'chiffre_affaires': _compagnie?.statistiques.chiffreAffaires ?? 0,
          'satisfaction': 4.2,
        };
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des KPIs: $e');
    }
  }

  /// 🎨 Couleur de la compagnie
  Color _getCompanyColor() {
    if (_compagnie?.couleur != null) {
      try {
        return Color(int.parse(_compagnie!.couleur.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  /// 🔔 Afficher les notifications
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Notifications'),
        content: const Text('Aucune nouvelle notification'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides
  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Actions Rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getCompanyColor(),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.add_circle, color: _getCompanyColor()),
              title: const Text('Nouveau Contrat'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Naviguer vers nouveau contrat
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: _getCompanyColor()),
              title: const Text('Déclarer Sinistre'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Naviguer vers déclaration sinistre
              },
            ),
            ListTile(
              leading: Icon(Icons.search, color: _getCompanyColor()),
              title: const Text('Rechercher Client'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Naviguer vers recherche
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Gérer les actions du menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'profile':
        // TODO: Naviguer vers profil
        break;
      case 'settings':
        // TODO: Naviguer vers paramètres
        break;
      case 'logout':
        // TODO: Déconnexion
        break;
    }
  }
}
