import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_compagnie_agence_service.dart';
import 'create_agence_only_screen.dart';
import 'edit_agence_screen.dart';
import 'agence_details_screen.dart';

/// 🏢 Gestion des Agences - Admin Compagnie
class AgentsByAgenceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AgentsByAgenceScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _AgentsByAgenceScreenState createState() => _AgentsByAgenceScreenState();
}

class _AgentsByAgenceScreenState extends State<AgentsByAgenceScreen> {
  List<Map<String, dynamic>> _agences = [];
  List<Map<String, dynamic>> _filteredAgences = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAgences();
    _searchController.addListener(_filterAgences);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 📊 Charger les agences
  Future<void> _loadAgences() async {
    setState(() => _isLoading = true);
    
    try {
      final agences = await AdminCompagnieAgenceService.getAgencesWithAdminStatus(
        widget.userData['compagnieId']
      );
      
      _agences = agences;
      _filterAgences();
    } catch (e) {
      debugPrint('Erreur chargement agences: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔍 Filtrer les agences
  void _filterAgences() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAgences = _agences.where((agence) {
        return agence['nom'].toString().toLowerCase().contains(query) ||
               agence['gouvernorat'].toString().toLowerCase().contains(query) ||
               agence['adresse'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Agences - testini',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAgences,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showCreateAgenceDialog,
            tooltip: 'Ajouter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF4CAF50)),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),

          // Statistiques en cartes
          _buildStatsCards(),

          // Liste des agences
          Expanded(
            child: _isLoading ? _buildLoadingScreen() : _buildSimpleAgencesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAgenceDialog,
        backgroundColor: Color(0xFF4CAF50),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalAgences = _agences.length;
    final agencesActives = _agences.where((a) => a['isActive'] == true).length;
    final agencesAvecAdmin = _agences.where((a) => a['hasAdmin'] == true).length;
    final agencesSansAdmin = totalAgences - agencesAvecAdmin;

    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              totalAgences.toString(),
              Icons.business,
              Color(0xFF2196F3),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Actives',
              agencesActives.toString(),
              Icons.check_circle,
              Color(0xFF4CAF50),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Avec Admin',
              agencesAvecAdmin.toString(),
              Icons.person,
              Color(0xFFFF9800),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Sans Admin',
              agencesSansAdmin.toString(),
              Icons.person_off,
              Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAgencesList() {
    if (_filteredAgences.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredAgences.length,
        itemBuilder: (context, index) {
          final agence = _filteredAgences[index];
          return _buildSimpleAgenceItem(agence);
        },
      ),
    );
  }

  Widget _buildSimpleAgenceItem(Map<String, dynamic> agence) {
    final hasAdmin = agence['hasAdmin'] == true;
    final isActive = agence['isActive'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Icône de l'agence
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.business,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
          SizedBox(width: 12),

          // Informations de l'agence
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agence['nom'] ?? 'Nom non défini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${agence['gouvernorat']} • ${agence['adresse']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Statuts
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasAdmin ? Icons.check_circle : Icons.cancel,
                    color: hasAdmin ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    hasAdmin ? 'Admin' : 'No Admin',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasAdmin ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Aucune agence trouvée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Commencez par créer une nouvelle agence',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }



  /// 🆕 Créer une nouvelle agence
  void _showCreateAgenceDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAgenceOnlyScreen(userData: widget.userData),
      ),
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Agence créée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAgences();
    }
  }

  /// 👁️ Voir les détails d'une agence
  void _viewAgenceDetails(Map<String, dynamic> agence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgenceDetailsScreen(
          agenceData: agence,
          userData: widget.userData,
        ),
      ),
    );
  }

  /// ✏️ Modifier une agence
  void _editAgence(Map<String, dynamic> agence) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAgenceScreen(
          agenceData: agence,
          userData: widget.userData,
        ),
      ),
    );

    if (result != null && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Agence modifiée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAgences();
    }
  }
}
