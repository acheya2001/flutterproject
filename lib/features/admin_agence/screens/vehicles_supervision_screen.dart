import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 👁️ Écran de supervision des véhicules pour l'admin agence
/// L'admin peut voir tous les véhicules traités par ses agents mais ne peut pas les modifier
class VehiclesSupervisionScreen extends StatefulWidget {
  const VehiclesSupervisionScreen({super.key});

  @override
  State<VehiclesSupervisionScreen> createState() => _VehiclesSupervisionScreenState();
}

class _VehiclesSupervisionScreenState extends State<VehiclesSupervisionScreen>with SingleTickerProviderStateMixin  {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  String? _agenceId;
  bool _isLoading = true;
  Map<String, dynamic>? _agenceInfo;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _tabController = TabController(length: 4, vsync: this);
    _loadAgenceInfo();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAgenceInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _agenceId = userData['agenceId'];
        
        if (_agenceId != null) {
          final agenceDoc = await _firestore.collection('agences').doc(_agenceId!).get();
          if (agenceDoc.exists) {
            _agenceInfo = agenceDoc.data();
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement info agence: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Supervision Véhicules', style: TextStyle(fontSize: 18)),
            if (_agenceInfo != null)
              Text(
                _agenceInfo!['nom'] ?? 'Agence',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En attente', icon: Icon(Icons.pending_actions, size: 20)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle, size: 20)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel, size: 20)),
            Tab(text: 'Contrats', icon: Icon(Icons.description, size: 20)),
          ],
        ),
      ),
      body: _agenceId == null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVehiclesList('En attente'),
                _buildVehiclesList('Validé par Agent'),
                _buildVehiclesList('Rejeté par Agent'),
                _buildVehiclesList('Contrat Proposé'),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            'Erreur de configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Agence non définie pour cet administrateur'),
        ],
      ),
    );
  }

  Widget _buildVehiclesList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('vehicules')
          .where('etatCompte', isEqualTo: status)
          .where('agenceAssuranceId', isEqualTo: _agenceId)
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red.shade400, size: 48),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vehicles = snapshot.data?.docs ?? [];

        if (vehicles.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Le stream se rafraîchit automatiquement
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicleData = vehicles[index].data() as Map<String, dynamic>;
              vehicleData['id'] = vehicles[index].id;
              return _buildVehicleCard(vehicleData, status);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    IconData icon;
    String message;
    Color color;

    switch (status) {
      case 'En attente':
        icon = Icons.pending_actions;
        message = 'Aucun véhicule en attente';
        color = Colors.orange;
        break;
      case 'Validé par Agent':
        icon = Icons.check_circle;
        message = 'Aucun véhicule validé';
        color = Colors.green;
        break;
      case 'Rejeté par Agent':
        icon = Icons.cancel;
        message = 'Aucun véhicule rejeté';
        color = Colors.red;
        break;
      case 'Contrat Proposé':
        icon = Icons.description;
        message = 'Aucun contrat proposé';
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        message = 'Aucun véhicule';
        color = Colors.grey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les véhicules traités par vos agents apparaîtront ici',
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

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'En attente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
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
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    final updatedAt = (vehicle['updatedAt'] as Timestamp?)?.toDate();
    final validatedBy = vehicle['validatedByEmail'] as String?;
    final rejectedBy = vehicle['rejectedByEmail'] as String?;
    final rejectionReason = vehicle['rejectionReason'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
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
            
            // Informations de traitement
            if (validatedBy != null) ...[
              _buildInfoRow('Validé par', validatedBy),
            ],
            if (rejectedBy != null) ...[
              _buildInfoRow('Rejeté par', rejectedBy),
              if (rejectionReason != null)
                _buildInfoRow('Raison', rejectionReason),
            ],
            if (updatedAt != null)
              _buildInfoRow('Traité le', _formatDate(updatedAt)),
            
            const SizedBox(height: 12),
            
            // Informations véhicule
            _buildInfoRow('Propriétaire', '${vehicle['nomProprietaire'] ?? ''} ${vehicle['prenomProprietaire'] ?? ''}'),
            _buildInfoRow('Année', vehicle['annee']?.toString() ?? 'N/A'),
            _buildInfoRow('Usage', vehicle['usage'] ?? 'N/A'),

            // Boutons d'action pour les véhicules en attente
            if (status == 'En attente') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveVehicle(vehicle),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignToAgent(vehicle),
                      icon: const Icon(Icons.assignment_ind, size: 16),
                      label: const Text('Affecter Agent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectVehicle(vehicle),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
            width: 100,
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// ✅ Approuver un véhicule
  Future<void> _approveVehicle(Map<String, dynamic> vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Approuver le véhicule'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous approuver ce véhicule ?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle['marque']} ${vehicle['modele']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Propriétaire: ${vehicle['nomProprietaire']} ${vehicle['prenomProprietaire']}'),
                  Text('Immatriculation: ${vehicle['numeroImmatriculation']}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore
            .collection('vehicules')
            .doc(vehicle['id'])
            .update({
          'etatCompte': 'Approuvé par Admin',
          'dateApprobation': FieldValue.serverTimestamp(),
          'approuvePar': _agenceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Véhicule approuvé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 👤 Affecter un véhicule à un agent
  Future<void> _assignToAgent(Map<String, dynamic> vehicle) async {
    // Charger la liste des agents de l'agence
    final agents = await _loadAgenceAgents();

    if (agents.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Aucun agent disponible'),
              ],
            ),
            content: const Text(
              'Aucun agent n\'est disponible dans cette agence pour traiter ce dossier.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
      return;
    }

    String? selectedAgentId;

    final shouldAssign = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assignment_ind, color: Colors.blue),
              SizedBox(width: 8),
              Text('Affecter à un agent'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sélectionnez un agent pour traiter ce dossier :'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle['marque']} ${vehicle['modele']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Propriétaire: ${vehicle['nomProprietaire']} ${vehicle['prenomProprietaire']}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAgentId,
                decoration: const InputDecoration(
                  labelText: 'Agent responsable *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: agents.map((agent) {
                  return DropdownMenuItem<String>(
                    value: agent['id'],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            '${agent['prenom']?[0] ?? ''}${agent['nom']?[0] ?? ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${agent['prenom']} ${agent['nom']}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (mounted) setState(() {
                    selectedAgentId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedAgentId != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Affecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (shouldAssign == true && selectedAgentId != null) {
      try {
        final selectedAgent = agents.firstWhere((agent) => agent['id'] == selectedAgentId);

        await _firestore
            .collection('vehicules')
            .doc(vehicle['id'])
            .update({
          'etatCompte': 'Affecté à Agent',
          'agentAffecteId': selectedAgentId,
          'agentAffecteNom': '${selectedAgent['prenom']} ${selectedAgent['nom']}',
          'agentAffecteEmail': selectedAgent['email'],
          'dateAffectation': FieldValue.serverTimestamp(),
          'affectePar': _agenceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Véhicule affecté à ${selectedAgent['prenom']} ${selectedAgent['nom']}'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur lors de l\'affectation: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ❌ Rejeter un véhicule
  Future<void> _rejectVehicle(Map<String, dynamic> vehicle) async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejeter le véhicule'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pourquoi rejetez-vous ce véhicule ?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle['marque']} ${vehicle['modele']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Propriétaire: ${vehicle['nomProprietaire']} ${vehicle['prenomProprietaire']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
                hintText: 'Ex: Documents manquants, informations incorrectes...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir une raison'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _firestore
            .collection('vehicules')
            .doc(vehicle['id'])
            .update({
          'etatCompte': 'Rejeté par Admin',
          'raisonRejet': reasonController.text.trim(),
          'dateRejet': FieldValue.serverTimestamp(),
          'rejetePar': _agenceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Véhicule rejeté'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 👥 Charger la liste des agents de l'agence
  Future<List<Map<String, dynamic>>> _loadAgenceAgents() async {
    try {
      final agentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: _agenceId)
          .where('statut', isEqualTo: 'actif')
          .get();

      final agents = <Map<String, dynamic>>[];

      for (final doc in agentsQuery.docs) {
        final agentData = doc.data();
        agentData['id'] = doc.id;
        agents.add(agentData);
      }

      return agents;
    } catch (e) {
      print('❌ Erreur chargement agents: $e');
      return [];
    }
  }
}

