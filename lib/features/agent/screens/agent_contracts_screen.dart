import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/contract_completion_service.dart';
import '../widgets/document_delivery_options_widget.dart';

/// 📋 Écran des contrats créés par l'agent
class AgentContractsScreen extends StatefulWidget {
  const AgentContractsScreen({Key? key}) : super(key: key);

  @override
  State<AgentContractsScreen> createState() => _AgentContractsScreenState();
}

class _AgentContractsScreenState extends State<AgentContractsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _agentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _agentId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Mes Contrats Créés',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _agentId == null
          ? const Center(
              child: Text(
                'Erreur: Agent non connecté',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _buildContractsList(),
    );
  }

  /// 📋 Liste des contrats
  Widget _buildContractsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('contrats')
          .where('agentId', isEqualTo: _agentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorMessage('Erreur lors du chargement des contrats');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final contracts = snapshot.data?.docs ?? [];

        if (contracts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            final contractData = contract.data() as Map<String, dynamic>;
            contractData['id'] = contract.id;

            return _buildContractCard(contractData);
          },
        );
      },
    );
  }

  /// 📄 Carte de contrat
  Widget _buildContractCard(Map<String, dynamic> contractData) {
    final statut = contractData['statut'] ?? '';
    final isActive = statut.toLowerCase() == 'actif';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [Colors.green.shade50, Colors.blue.shade50]
              : [Colors.grey.shade100, Colors.grey.shade200],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du contrat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contrat N° ${contractData['numeroContrat'] ?? ''}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contractData['vehiculeInfo']?['immatriculation'] ?? 'Véhicule',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? '✅ Actif' : '⏸️ ${statut}',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations du véhicule et conducteur
            Row(
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${contractData['vehiculeInfo']?['marque'] ?? ''} ${contractData['vehiculeInfo']?['modele'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${contractData['proprietaireInfo']?['prenom'] ?? ''} ${contractData['proprietaireInfo']?['nom'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Valide jusqu\'au ${_formatDate(contractData['dateFin'])}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Boutons d'action
            if (isActive) _buildActionButtons(contractData),
          ],
        ),
      ),
    );
  }

  /// 🎯 Boutons d'action pour contrat actif
  Widget _buildActionButtons(Map<String, dynamic> contractData) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _showDeliveryOptions(contractData),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isLoading ? 'Envoi...' : 'Envoyer Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewContractDetails(contractData),
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Voir Détails'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📤 Afficher les options de livraison
  void _showDeliveryOptions(Map<String, dynamic> contractData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDeliveryOptionsWidget(
        contractData: contractData,
        onDeliveryComplete: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }

  /// 📤 Envoyer les documents d'assurance au conducteur (méthode simple)
  Future<void> _sendInsuranceDocuments(Map<String, dynamic> contractData) async {
    try {
      setState(() => _isLoading = true);

      // Utiliser le service de finalisation de contrat
      final results = await ContractCompletionService.completeContractProcess(
        contractId: contractData['id'],
        vehicleId: contractData['vehiculeId'],
        conducteurId: contractData['conducteurId'],
        contractData: contractData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅ Documents envoyés avec succès !'),
                      Text(
                        'Carte verte, quittance et certificat générés',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 👁️ Voir les détails du contrat
  void _viewContractDetails(Map<String, dynamic> contractData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contrat N° ${contractData['numeroContrat']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Véhicule', '${contractData['vehiculeInfo']?['marque']} ${contractData['vehiculeInfo']?['modele']}'),
              _buildDetailRow('Immatriculation', contractData['vehiculeInfo']?['immatriculation'] ?? ''),
              _buildDetailRow('Conducteur', '${contractData['proprietaireInfo']?['prenom']} ${contractData['proprietaireInfo']?['nom']}'),
              _buildDetailRow('Type', contractData['typeContratDisplay'] ?? contractData['typeContrat'] ?? ''),
              _buildDetailRow('Prime annuelle', '${contractData['primeAnnuelle'] ?? 0} DT'),
              _buildDetailRow('Début', _formatDate(contractData['dateDebut'])),
              _buildDetailRow('Fin', _formatDate(contractData['dateFin'])),
              _buildDetailRow('Statut', contractData['statut'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📊 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat créé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les contrats que vous créez apparaîtront ici',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// ❌ Message d'erreur
  Widget _buildErrorMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return date.toString();
    }
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}

