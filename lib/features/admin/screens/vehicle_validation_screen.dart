import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/insurance/models/insurance_structure_model.dart';
import '../../../services/digital_contract_service.dart';
// import '../../../common/widgets/custom_app_bar.dart';
// import '../../../common/widgets/loading_overlay.dart';

/// 🏢 Écran de validation des véhicules par l'admin agence
class VehicleValidationScreen extends StatefulWidget {
  const VehicleValidationScreen({Key? key}) : super(key: key);

  @override
  State<VehicleValidationScreen> createState() => _VehicleValidationScreenState();
}

class _VehicleValidationScreenState extends State<VehicleValidationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _agenceId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _agents = [];

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
      final userData = userDoc.data();
      
      if (userData != null) {
        setState(() {
          _agenceId = userData['agenceId'];
          _isLoading = false;
        });
        
        if (_agenceId != null) {
          _loadAgents();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement: $e');
    }
  }

  Future<void> _loadAgents() async {
    try {
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: _agenceId)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _agents = agentsQuery.docs.map((doc) => {
          'id': doc.id,
          'nom': doc.data()['nom'] ?? '',
          'prenom': doc.data()['prenom'] ?? '',
          'email': doc.data()['email'] ?? '',
        }).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des agents: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_agenceId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Validation Véhicules'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur: Agence non trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation Véhicules'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('vehicules_en_attente')
            .where('agenceId', isEqualTo: _agenceId)
            .where('status', isEqualTo: VehicleStatus.enAttenteValidation.value)
            .orderBy('submittedAt', descending: true)
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
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicleData = vehicles[index].data() as Map<String, dynamic>;
              final vehicleId = vehicles[index].id;
              
              return _buildVehicleCard(vehicleId, vehicleData);
            },
          );
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
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune demande en attente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes les demandes ont été traitées',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(String vehicleId, Map<String, dynamic> data) {
    final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
    final timeAgo = submittedAt != null 
        ? _getTimeAgo(submittedAt)
        : 'Date inconnue';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'En attente',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations véhicule
            _buildInfoSection('🚗 Véhicule', [
              _buildInfoRow('Marque/Modèle', '${data['marque']} ${data['modele']}'),
              _buildInfoRow('Immatriculation', data['numeroImmatriculation'] ?? ''),
              _buildInfoRow('Année', '${data['annee'] ?? ''}'),
              _buildInfoRow('Type', data['typeVehicule'] ?? ''),
            ]),

            const SizedBox(height: 16),

            // Informations conducteur
            _buildInfoSection('👤 Conducteur', [
              _buildInfoRow('Nom', '${data['conducteurPrenom']} ${data['conducteurNom']}'),
              _buildInfoRow('Téléphone', data['conducteurTelephone'] ?? ''),
              _buildInfoRow('Email', data['conducteurEmail'] ?? ''),
              _buildInfoRow('Permis', data['permisNumber'] ?? ''),
            ]),

            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(vehicleId, data),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showValidateDialog(vehicleId, data),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider & Assigner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                fontSize: 13,
                fontWeight: value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidateDialog(String vehicleId, Map<String, dynamic> vehicleData) {
    String? selectedAgentId;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Véhicule: ${vehicleData['marque']} ${vehicleData['modele']} (${vehicleData['numeroImmatriculation']})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('Assigner à un agent:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedAgentId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Choisir un agent',
              ),
              items: _agents.map((agent) {
                return DropdownMenuItem<String>(
                  value: agent['id'],
                  child: Text('${agent['prenom']} ${agent['nom']}'),
                );
              }).toList(),
              onChanged: (value) => selectedAgentId = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Notes (optionnel)',
                hintText: 'Instructions pour l\'agent...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedAgentId != null) {
                Navigator.of(context).pop();
                _validateVehicle(vehicleId, selectedAgentId!, notesController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String vehicleId, Map<String, dynamic> vehicleData) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Véhicule: ${vehicleData['marque']} ${vehicleData['modele']} (${vehicleData['numeroImmatriculation']})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Raison du rejet *',
                hintText: 'Expliquez pourquoi la demande est rejetée...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                _rejectVehicle(vehicleId, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateVehicle(String vehicleId, String agentId, String notes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await DigitalContractService.validateVehicleByAdmin(
        vehicleId: vehicleId,
        adminId: user.uid,
        assignedAgentId: agentId,
        notes: notes.isNotEmpty ? notes : null,
      );

      _showSuccessSnackBar('Véhicule validé et assigné avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la validation: $e');
    }
  }

  Future<void> _rejectVehicle(String vehicleId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      await DigitalContractService.rejectVehicleByAdmin(
        vehicleId: vehicleId,
        adminId: user.uid,
        rejectionReason: reason,
      );

      _showSuccessSnackBar('Demande rejetée');
    } catch (e) {
      _showErrorSnackBar('Erreur lors du rejet: $e');
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
