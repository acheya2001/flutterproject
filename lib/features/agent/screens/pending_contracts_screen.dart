import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/contract_service.dart';
import 'create_contract_screen.dart';

/// 📋 Écran des véhicules en attente de contrat pour l'agent
class PendingContractsScreen extends StatefulWidget {
  const PendingContractsScreen({Key? key}) : super(key: key);

  @override
  State<PendingContractsScreen> createState() => _PendingContractsScreenState();
}

class _PendingContractsScreenState extends State<PendingContractsScreen> {
  String? _agenceId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadAgentInfo();
    });
  }

  Future<void> _loadAgentInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final agentDoc = await FirebaseFirestore.instance
          .collection('agents_assurance')
          .doc(currentUser.uid)
          .get();

      if (agentDoc.exists) {
        if (mounted) setState(() {
          _agenceId = agentDoc.data()!['agenceId'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement agent: $e');
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

    if (_agenceId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Véhicules en attente'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur: Agence non trouvée'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules en attente de contrat'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ContractService.getPendingVehicles(_agenceId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicules = snapshot.data?.docs ?? [];

          if (vehicules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun véhicule en attente',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les nouveaux véhicules apparaîtront ici',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicules.length,
            itemBuilder: (context, index) {
              final vehiculeDoc = vehicules[index];
              final vehiculeData = vehiculeDoc.data() as Map<String, dynamic>;
              
              return _buildVehiculeCard(vehiculeDoc.id, vehiculeData);
            },
          );
        },
      ),
    );
  }

  Widget _buildVehiculeCard(String vehiculeId, Map<String, dynamic> vehiculeData) {
    final marque = vehiculeData['marque'] ?? '';
    final modele = vehiculeData['modele'] ?? '';
    final immatriculation = vehiculeData['immatriculation'] ?? '';
    final annee = vehiculeData['annee']?.toString() ?? '';
    final couleur = vehiculeData['couleur'] ?? '';
    final conducteurId = vehiculeData['conducteurId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  child: Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.directions_car,
                  color: Colors.blue.shade600,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Infos véhicule
            Text(
              '$marque $modele',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.confirmation_number, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  immatriculation,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                if (annee.isNotEmpty) ...[
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(annee, style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(width: 16),
                ],
                if (couleur.isNotEmpty) ...[
                  Icon(Icons.palette, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(couleur, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Infos conducteur
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(conducteurId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final conducteurData = snapshot.data!.data() as Map<String, dynamic>;
                  final nom = '${conducteurData['prenom'] ?? ''} ${conducteurData['nom'] ?? ''}'.trim();
                  final telephone = conducteurData['telephone'] ?? '';
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conducteur',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nom.isNotEmpty ? nom : 'Nom non disponible',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (telephone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            telephone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Bouton d'action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createContract(vehiculeId, vehiculeData),
                icon: const Icon(Icons.assignment_add),
                label: const Text('Créer le contrat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createContract(String vehiculeId, Map<String, dynamic> vehiculeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateContractScreen(
          vehiculeId: vehiculeId,
          vehiculeData: vehiculeData,
          agenceId: _agenceId!,
        ),
      ),
    );
  }
}

