import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/universal_auth_service.dart';

/// 👨‍💼 Écran d'administration pour gérer les demandes d'inscription
class AdminDemandesScreen extends StatefulWidget {
  const AdminDemandesScreen({Key? key}) : super(key: key);

  @override
  State<AdminDemandesScreen> createState() => _AdminDemandesScreenState();
}

class _AdminDemandesScreenState extends State<AdminDemandesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'Inscription'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('demandes_inscription')
            .where('statut', isEqualTo: 'en_attente')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final demandes = snapshot.data?.docs ?? [];

          if (demandes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune demande en attente',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: demandes.length,
            itemBuilder: (context, index) {
              final demande = demandes[index];
              final data = demande.data() as Map<String, dynamic>;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              '${data['prenom']?[0] ?? ''}${data['nom']?[0] ?? ''}',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${data['prenom']} ${data['nom']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data['email'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Informations professionnelles
                      _buildInfoRow('Compagnie', data['compagnie']),
                      _buildInfoRow('Agence', data['agence']),
                      _buildInfoRow('Gouvernorat', data['gouvernorat']),
                      _buildInfoRow('Poste', data['poste']),
                      _buildInfoRow('Numéro Agent', data['numeroAgent']),
                      _buildInfoRow('Téléphone', data['telephone']),
                      
                      const SizedBox(height: 16),
                      
                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approuverDemande(demande.id, data),
                              icon: const Icon(Icons.check),
                              label: const Text('Approuver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _refuserDemande(demande.id),
                              icon: const Icon(Icons.close),
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
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Non spécifié'),
          ),
        ],
      ),
    );
  }

  Future<void> _approuverDemande(String demandeId, Map<String, dynamic> data) async {
    try {
      // Créer le compte Firebase Auth et Firestore
      final result = await UniversalAuthService.signUp(
        email: data['email'],
        password: data['motDePasseTemporaire'],
        nom: data['nom'],
        prenom: data['prenom'],
        userType: 'assureur',
        additionalData: {
          'telephone': data['telephone'],
          'compagnie': data['compagnie'],
          'agence': data['agence'],
          'gouvernorat': data['gouvernorat'],
          'poste': data['poste'],
          'numeroAgent': data['numeroAgent'],
        },
      );

      if (result['success'] == true) {
        // Marquer la demande comme approuvée
        await _firestore.collection('demandes_inscription').doc(demandeId).update({
          'statut': 'approuvee',
          'dateApprobation': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Demande approuvée: ${data['prenom']} ${data['nom']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['error']);
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

  Future<void> _refuserDemande(String demandeId) async {
    try {
      await _firestore.collection('demandes_inscription').doc(demandeId).update({
        'statut': 'refusee',
        'dateRefus': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Demande refusée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
