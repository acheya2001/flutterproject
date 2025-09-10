import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/vehicle_workflow_service.dart';

/// 🚗 Écran de gestion des véhicules pour l'admin agence
class VehicleManagementScreen extends StatefulWidget {
  final String agenceId;

  const VehicleManagementScreen({
    Key? key,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _vehicules = [];
  List<Map<String, dynamic>> _agents = [];
  Map<String, dynamic>? _statistiques;
  bool _isLoading = true;
  String _filtreEtat = 'Tous';
  String? _filtreAgent;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Gestion des Véhicules',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  /// 📊 Contenu principal
  Widget _buildContent() {
    return Column(
      children: [
        // Statistiques rapides
        _buildQuickStats(),
        
        // Filtres et recherche
        _buildFiltersSection(),
        
        // Liste des véhicules
        Expanded(
          child: _buildVehiclesList(),
        ),
      ],
    );
  }

  /// 📈 Statistiques rapides
  Widget _buildQuickStats() {
    if (_statistiques == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Aperçu Général',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  '${_statistiques!['total']}',
                  Icons.directions_car,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'En Attente',
                  '${_statistiques!['enAttente']}',
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Affectés',
                  '${_statistiques!['affectes']}',
                  Icons.assignment_ind,
                  Colors.purple,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Assurés',
                  '${_statistiques!['assures']}',
                  Icons.verified,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
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
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 🔍 Section filtres et recherche
  Widget _buildFiltersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par marque, modèle ou immatriculation...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (_) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          
          // Filtres
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtreEtat,
                  decoration: const InputDecoration(
                    labelText: 'État',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous les états')),
                    DropdownMenuItem(value: 'En attente', child: Text('En attente')),
                    DropdownMenuItem(value: 'Validé par Admin', child: Text('Validés')),
                    DropdownMenuItem(value: 'Affecté à Agent', child: Text('Affectés')),
                    DropdownMenuItem(value: 'Assuré', child: Text('Assurés')),
                    DropdownMenuItem(value: 'Rejeté', child: Text('Rejetés')),
                  ],
                  onChanged: (value) {
                    setState(() => _filtreEtat = value!);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtreAgent,
                  decoration: const InputDecoration(
                    labelText: 'Agent',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les agents')),
                    ..._agents.map((agent) => DropdownMenuItem(
                      value: agent['id'],
                      child: Text('${agent['prenom']} ${agent['nom']}'),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _filtreAgent = value);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Liste des véhicules
  Widget _buildVehiclesList() {
    if (_vehicules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun véhicule trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun véhicule ne correspond aux critères de recherche',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _vehicules.length,
        itemBuilder: (context, index) {
          final vehicule = _vehicules[index];
          return _buildVehicleCard(vehicule);
        },
      ),
    );
  }

  /// 🚗 Carte véhicule
  Widget _buildVehicleCard(Map<String, dynamic> vehicule) {
    final etat = vehicule['etatCompte'] ?? 'En attente';
    final conducteurInfo = vehicule['conducteurInfo'] as Map<String, dynamic>?;
    final agentInfo = vehicule['agentInfo'] as Map<String, dynamic>?;
    
    Color statusColor = _getStatusColor(etat);
    IconData statusIcon = _getStatusIcon(etat);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _showVehicleDetails(vehicule),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicule['marque']} ${vehicule['modele']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehicule['numeroImmatriculation'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      etat.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Informations conducteur
              if (conducteurInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${conducteurInfo['prenom']} ${conducteurInfo['nom']} • ${conducteurInfo['telephone']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Agent affecté
              if (agentInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_ind, color: Colors.purple.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Agent: ${agentInfo['prenom']} ${agentInfo['nom']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Actions selon l'état
              _buildActionButtons(vehicule, etat),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Boutons d'action selon l'état
  Widget _buildActionButtons(Map<String, dynamic> vehicule, String etat) {
    switch (etat) {
      case 'En attente':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _validerVehicule(vehicule['id']),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejeterVehicule(vehicule['id']),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Rejeter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
        
      case 'Validé par Admin':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _affecterAgent(vehicule),
            icon: const Icon(Icons.assignment_ind, size: 18),
            label: const Text('Affecter à un Agent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
        
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showVehicleDetails(vehicule),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Détails'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  side: BorderSide(color: Colors.blue.shade600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (etat == 'Affecté à Agent') ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reassignerAgent(vehicule),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Réassigner'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade600,
                    side: BorderSide(color: Colors.orange.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  /// 🔧 Méthodes utilitaires
  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Color _getStatusColor(String etat) {
    switch (etat) {
      case 'En attente': return Colors.orange;
      case 'Validé par Admin': return Colors.blue;
      case 'Affecté à Agent': return Colors.purple;
      case 'Assuré': return Colors.green;
      case 'Rejeté': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String etat) {
    switch (etat) {
      case 'En attente': return Icons.pending_actions;
      case 'Validé par Admin': return Icons.verified;
      case 'Affecté à Agent': return Icons.assignment_ind;
      case 'Assuré': return Icons.shield;
      case 'Rejeté': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  /// 📊 Charger les données
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les statistiques
      _statistiques = await VehicleWorkflowService.getStatistiquesWorkflow(widget.agenceId);
      
      // Charger les agents de l'agence
      await _loadAgents();
      
      // Charger les véhicules
      await _applyFilters();
      
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAgents() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('agenceId', isEqualTo: widget.agenceId)
          .where('role', isEqualTo: 'agent')
          .get();

      _agents = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      debugPrint('Erreur chargement agents: $e');
    }
  }

  Future<void> _applyFilters() async {
    try {
      _vehicules = await VehicleWorkflowService.rechercherVehicules(
        agenceId: widget.agenceId,
        etat: _filtreEtat == 'Tous' ? null : _filtreEtat,
        agentId: _filtreAgent,
        recherche: _searchController.text,
      );
      
      if (mounted) setState(() {});
      
    } catch (e) {
      debugPrint('Erreur application filtres: $e');
    }
  }

  /// 🎯 Actions
  Future<void> _validerVehicule(String vehiculeId) async {
    final success = await VehicleWorkflowService.validerVehiculeParAdmin(
      vehiculeId: vehiculeId,
      adminId: FirebaseAuth.instance.currentUser!.uid,
      agenceId: widget.agenceId,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Véhicule validé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la validation'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejeterVehicule(String vehiculeId) {
    // TODO: Implémenter le rejet avec motif
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le véhicule'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _affecterAgent(Map<String, dynamic> vehicule) {
    // TODO: Implémenter l'affectation d'agent
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Affecter à un agent'),
        content: const Text('Fonctionnalité à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _reassignerAgent(Map<String, dynamic> vehicule) {
    // TODO: Implémenter la réassignation
  }

  void _showVehicleDetails(Map<String, dynamic> vehicule) {
    // TODO: Implémenter les détails
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

