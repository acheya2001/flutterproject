import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// 🚗 Dashboard Conducteur Test (Version fonctionnelle)
class ConducteurDashboardTest extends StatefulWidget {
  const ConducteurDashboardTest({Key? key}) : super(key: key);

  @override
  State<ConducteurDashboardTest> createState() => _ConducteurDashboardTestState();
}

class _ConducteurDashboardTestState extends State<ConducteurDashboardTest> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _sinistres = [];
  List<Map<String, dynamic>> _sessionsCollaboratives = [];
  bool _isLoading = true;
  String _nomConducteur = 'Conducteur';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _chargerSessionsCollaboratives();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _nomConducteur = user.displayName ?? user.email?.split('@').first ?? 'Conducteur';
        });
      }
    } catch (e) {
      print('❌ Erreur chargement utilisateur: $e');
    }
    
    setState(() => _isLoading = false);
  }

  /// 📋 Charger les sessions collaboratives
  Future<void> _chargerSessionsCollaboratives() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final sessionsQuery = await FirebaseFirestore.instance
          .collection('sessions_collaboratives')
          .where('createurId', isEqualTo: user.uid)
          .orderBy('dateCreation', descending: true)
          .limit(10)
          .get();

      final List<Map<String, dynamic>> sessions = [];

      for (var doc in sessionsQuery.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        sessions.add(data);
      }

      if (mounted) {
        setState(() {
          _sessionsCollaboratives = sessions;
        });
      }

      print('✅ ${sessions.length} sessions collaboratives chargées');

    } catch (e) {
      print('❌ Erreur chargement sessions collaboratives: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Test - $_nomConducteur'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildAccueilPage(),
                _buildSinistresPage(),
                _buildVehiculesPage(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.warning),
                if (_sessionsCollaboratives.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_sessionsCollaboratives.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Sinistres',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Véhicules',
          ),
        ],
      ),
    );
  }

  /// 🏠 Page d'accueil
  Widget _buildAccueilPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de bienvenue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue $_nomConducteur !',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gérez vos sinistres et véhicules en toute simplicité',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistiques
          _buildStatistiques(),

          const SizedBox(height: 24),

          // Actions rapides
          _buildActionsRapides(),
        ],
      ),
    );
  }

  /// 📊 Statistiques
  Widget _buildStatistiques() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Mes Statistiques',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sessions\nCollaboratives',
                '${_sessionsCollaboratives.length}',
                Icons.group,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sinistres\nIndividuels',
                '${_sinistres.length}',
                Icons.warning,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📋 Carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides
  Widget _buildActionsRapides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Nouveau Constat',
                Icons.add_circle,
                Colors.green,
                () => _creerNouvelleSession(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Rejoindre Session',
                Icons.group_add,
                Colors.blue,
                () => _rejoindreSesssion(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🔘 Bouton d'action
  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚨 Page des sinistres
  Widget _buildSinistresPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚨 Mes Sinistres',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Sessions collaboratives
          _buildSessionsCollaboratives(),
        ],
      ),
    );
  }

  /// 👥 Sessions collaboratives
  Widget _buildSessionsCollaboratives() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sessions Collaboratives',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_sessionsCollaboratives.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_sessionsCollaboratives.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Aucune session collaborative trouvée',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ] else ...[
          ..._sessionsCollaboratives.map((session) => _buildSessionCard(session)).toList(),
        ],
      ],
    );
  }

  /// 📋 Carte de session
  Widget _buildSessionCard(Map<String, dynamic> session) {
    final code = session['code'] ?? 'N/A';
    final statut = session['statut'] ?? 'en_cours';
    final dateCreation = session['dateCreation'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Session $code',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatutColor(statut),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statut.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dateCreation != null) ...[
            Text(
              'Créée le ${DateFormat('dd/MM/yyyy à HH:mm').format(dateCreation.toDate())}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 🎨 Couleur selon le statut
  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'termine':
        return Colors.green;
      case 'en_cours':
        return Colors.orange;
      case 'en_attente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// 🚗 Page des véhicules
  Widget _buildVehiculesPage() {
    return const Center(
      child: Text(
        '🚗 Mes Véhicules\n(En cours de développement)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 🆕 Créer nouvelle session
  void _creerNouvelleSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Création de session en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 🔄 Rejoindre session
  void _rejoindreSesssion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rejoindre session en cours de développement'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
