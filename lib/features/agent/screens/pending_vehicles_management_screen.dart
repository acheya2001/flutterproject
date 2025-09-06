import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../conducteur/models/vehicule_model.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../services/agent_contract_service.dart';
import 'tunisian_contract_creation_screen.dart';

/// 🚗 Écran de gestion des véhicules affectés à l'agent - Système Tunisien
class PendingVehiclesManagementScreen extends StatefulWidget {
  const PendingVehiclesManagementScreen({super.key});

  @override
  State<PendingVehiclesManagementScreen> createState() => _PendingVehiclesManagementScreenState();
}

class _PendingVehiclesManagementScreenState extends State<PendingVehiclesManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _pendingVehicles = [];
  bool _isLoading = true;
  String? _userRole;
  String? _agenceId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _userRole = userData['role'];
        _agenceId = userData['agenceId'];
        
        await _loadPendingVehicles();
      }
    } catch (e) {
      print('❌ Erreur chargement info utilisateur: $e');
    }
  }

  Future<void> _loadPendingVehicles() async {
    try {
      setState(() => _isLoading = true);

      Query query = _firestore.collection('vehicules')
          .where('etatCompte', isEqualTo: 'En attente');

      // Filtrer par agence pour les agents ET les admins d'agence
      if ((_userRole == 'agent' || _userRole == 'admin_agence') && _agenceId != null) {
        query = query.where('agenceAssuranceId', isEqualTo: _agenceId);
        print('🔍 Filtrage par agence: $_agenceId pour rôle: $_userRole');
      } else {
        print('⚠️ Pas de filtrage par agence - Rôle: $_userRole, AgenceId: $_agenceId');
      }

      final snapshot = await query.get();
      print('📊 ${snapshot.docs.length} véhicules trouvés en attente');

      final vehicles = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final vehicleData = doc.data() as Map<String, dynamic>;
        vehicleData['id'] = doc.id;

        print('🚗 Véhicule trouvé: ${vehicleData['marque']} ${vehicleData['modele']} - Agence: ${vehicleData['agenceAssuranceId']}');

        // Récupérer les infos du conducteur depuis la collection 'users' (plus cohérent)
        final conducteurId = vehicleData['conducteurId'];
        if (conducteurId != null) {
          // Essayer d'abord dans 'users'
          final userDoc = await _firestore
              .collection('users')
              .doc(conducteurId)
              .get();

          if (userDoc.exists) {
            vehicleData['conducteurInfo'] = userDoc.data();
          } else {
            // Fallback vers 'conducteurs'
            final conducteurDoc = await _firestore
                .collection('conducteurs')
                .doc(conducteurId)
                .get();

            if (conducteurDoc.exists) {
              vehicleData['conducteurInfo'] = conducteurDoc.data();
            }
          }
        }

        vehicles.add(vehicleData);
      }

      setState(() {
        _pendingVehicles = vehicles;
        _isLoading = false;
      });

      print('✅ ${vehicles.length} véhicules chargés avec succès');
    } catch (e) {
      print('❌ Erreur chargement véhicules en attente: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Véhicules en Attente',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_pendingVehicles.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPendingVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = _pendingVehicles[index];
          return _buildVehicleCard(vehicle);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'Aucun véhicule en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les nouveaux véhicules ajoutés par les conducteurs apparaîtront ici',
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

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final conducteurInfo = vehicle['conducteurInfo'] as Map<String, dynamic>?;
    final createdAt = (vehicle['createdAt'] as Timestamp?)?.toDate();
    final etatCompte = vehicle['etatCompte'] ?? 'En attente';

    // Déterminer la couleur selon l'état
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.pending_actions;

    if (etatCompte == 'Affecté à Agent') {
      statusColor = Colors.blue;
      statusIcon = Icons.assignment_ind;
    } else if (etatCompte == 'Assuré') {
      statusColor = Colors.green;
      statusIcon = Icons.verified;
    }

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
        onTap: () => _showVehicleDetails(vehicle),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec statut
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
                          '${vehicle['marque']} ${vehicle['modele']}',
                          style: const TextStyle(
                            fontSize: 18,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      etatCompte.toUpperCase(),
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

              // Informations véhicule tunisiennes
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚗 Informations Véhicule',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow('Immatriculation', vehicle['numeroImmatriculation'] ?? 'N/A')),
                        Expanded(child: _buildInfoRow('Année', vehicle['annee']?.toString() ?? 'N/A')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildInfoRow('Puissance', '${vehicle['puissanceFiscale'] ?? 'N/A'} CV')),
                        Expanded(child: _buildInfoRow('Carburant', vehicle['carburant'] ?? 'N/A')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Type', vehicle['typeVehicule'] ?? 'N/A'),
                  ],
                ),
              ),
              
              if (conducteurInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👤 Informations Conducteur',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('Nom complet', '${conducteurInfo['prenom'] ?? ''} ${conducteurInfo['nom'] ?? ''}'),
                      _buildInfoRow('CIN', conducteurInfo['cin'] ?? 'N/A'),
                      _buildInfoRow('Téléphone', conducteurInfo['telephone'] ?? 'N/A'),
                      _buildInfoRow('Email', conducteurInfo['email'] ?? 'N/A'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Actions selon l'état
              if (etatCompte == 'Affecté à Agent') ...[
                // Véhicule affecté - Peut créer un contrat
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _createTunisianContract(vehicle),
                    icon: const Icon(Icons.assignment_add, size: 20),
                    label: const Text('Créer Contrat d\'Assurance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showVehicleDetails(vehicle),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade600,
                          side: BorderSide(color: Colors.blue.shade600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _contactConducteur(conducteurInfo),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Contacter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade600,
                          side: BorderSide(color: Colors.orange.shade600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (etatCompte == 'Assuré') ...[
                // Véhicule déjà assuré
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade600, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Véhicule Assuré',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'Ce véhicule possède déjà un contrat d\'assurance actif',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // État en attente ou autre
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _validateVehicle(vehicle['id']),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectVehicle(vehicle['id']),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Ajouté le ${_formatDate(createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
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
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
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

  void _showVehicleDetails(Map<String, dynamic> vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
      ),
    );
  }

  // Méthodes utilitaires (simplifiées pour éviter les erreurs)
  Future<void> _validateVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': 'Validé par Agent',
        'validatedAt': FieldValue.serverTimestamp(),
        'validatedBy': _auth.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Véhicule validé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _loadPendingVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': 'Rejeté par Agent',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Véhicule rejeté'),
          backgroundColor: Colors.red,
        ),
      );

      _loadPendingVehicles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createTunisianContract(Map<String, dynamic> vehicle) {
    // Navigation vers l'écran de création de contrat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Création de contrat - En développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _contactConducteur(Map<String, dynamic>? conducteurInfo) {
    if (conducteurInfo == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📞 Contact: ${conducteurInfo['telephone'] ?? 'N/A'}'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Écran de détails simplifié
class VehicleDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${vehicle['marque']} ${vehicle['modele']}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations Véhicule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Marque', vehicle['marque']),
                    _buildDetailRow('Modèle', vehicle['modele']),
                    _buildDetailRow('Immatriculation', vehicle['numeroImmatriculation']),
                    _buildDetailRow('Année', vehicle['annee']?.toString()),
                    _buildDetailRow('Couleur', vehicle['couleur']),
                    _buildDetailRow('Type', vehicle['typeVehicule']),
                    _buildDetailRow('Carburant', vehicle['carburant']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non spécifié',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
