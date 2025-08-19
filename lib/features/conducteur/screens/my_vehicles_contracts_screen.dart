import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🚗 Écran pour que le conducteur voie ses véhicules et contrats
class MyVehiclesContractsScreen extends StatefulWidget {
  const MyVehiclesContractsScreen({super.key});

  @override
  State<MyVehiclesContractsScreen> createState() => _MyVehiclesContractsScreenState();
}

class _MyVehiclesContractsScreenState extends State<MyVehiclesContractsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  String? _conducteurId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _conducteurId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Véhicules & Contrats'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mes Véhicules', icon: Icon(Icons.directions_car, size: 20)),
            Tab(text: 'Mes Contrats', icon: Icon(Icons.description, size: 20)),
          ],
        ),
      ),
      body: _conducteurId == null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVehiclesList(),
                _buildContractsList(),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Erreur: Utilisateur non connecté'),
        ],
      ),
    );
  }

  Widget _buildVehiclesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vehicules')
          .where('conducteurId', isEqualTo: _conducteurId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicles = snapshot.data?.docs ?? [];

        if (vehicles.isEmpty) {
          return _buildEmptyVehiclesState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicleData = vehicles[index].data() as Map<String, dynamic>;
            vehicleData['id'] = vehicles[index].id;
            return _buildVehicleCard(vehicleData);
          },
        );
      },
    );
  }

  Widget _buildContractsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('contrats')
          .where('conducteurId', isEqualTo: _conducteurId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final contracts = snapshot.data?.docs ?? [];

        if (contracts.isEmpty) {
          return _buildEmptyContractsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contractData = contracts[index].data() as Map<String, dynamic>;
            contractData['id'] = contracts[index].id;
            return _buildContractCard(contractData);
          },
        );
      },
    );
  }

  Widget _buildEmptyVehiclesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule ajouté',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier véhicule pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Naviguer vers l'écran d'ajout de véhicule
              Navigator.pushNamed(context, '/add-vehicle');
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un véhicule'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContractsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos contrats d\'assurance apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final status = vehicle['etatCompte'] as String? ?? 'En attente';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Validé par Agent':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejeté par Agent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Contrat Proposé':
        statusColor = Colors.blue;
        statusIcon = Icons.description;
        break;
      case 'Contrat Actif':
        statusColor = Colors.purple;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        '${vehicle['marque']} ${vehicle['modele']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicle['numeroImmatriculation'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Année', vehicle['annee']?.toString() ?? 'N/A'),
            _buildInfoRow('Couleur', vehicle['couleur'] ?? 'N/A'),
            _buildInfoRow('Usage', vehicle['usage'] ?? 'N/A'),
            if (vehicle['rejectionReason'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison du rejet: ${vehicle['rejectionReason']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final status = contract['statut'] as String? ?? 'Proposé';
    final vehicleInfo = contract['vehiculeInfo'] as Map<String, dynamic>? ?? {};
    final dateDebut = (contract['dateDebut'] as Timestamp?)?.toDate();
    final dateFin = (contract['dateFin'] as Timestamp?)?.toDate();
    final prime = contract['primeAnnuelle'] as double? ?? 0.0;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'actif':
        statusColor = Colors.green;
        break;
      case 'proposé':
        statusColor = Colors.blue;
        break;
      case 'rejeté':
        statusColor = Colors.red;
        break;
      case 'expiré':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Icon(Icons.description, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract['typeContratDisplay'] ?? 'Contrat',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'N° ${contract['numeroContrat'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Véhicule', '${vehicleInfo['marque'] ?? ''} ${vehicleInfo['modele'] ?? ''}'),
            _buildInfoRow('Prime annuelle', '${prime.toStringAsFixed(0)} TND'),
            if (dateDebut != null)
              _buildInfoRow('Date début', _formatDate(dateDebut)),
            if (dateFin != null)
              _buildInfoRow('Date fin', _formatDate(dateFin)),
            
            if (status.toLowerCase() == 'proposé') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptContract(contract['id']),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectContract(contract['id']),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Refuser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _acceptContract(String contractId) async {
    try {
      await _firestore.collection('contrats').doc(contractId).update({
        'statut': 'Actif',
        'acceptedAt': FieldValue.serverTimestamp(),
        'acceptedBy': _conducteurId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrat accepté avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectContract(String contractId) async {
    try {
      await _firestore.collection('contrats').doc(contractId).update({
        'statut': 'Rejeté',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _conducteurId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrat refusé'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
