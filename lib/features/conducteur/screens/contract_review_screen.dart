import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../features/insurance/models/digital_contract_model.dart';

// import '../../../common/widgets/custom_app_bar.dart';
// import '../../../common/widgets/loading_overlay.dart';

/// 📋 Écran pour que le conducteur examine et accepte les contrats proposés
class ContractReviewScreen extends StatefulWidget {
  const ContractReviewScreen({Key? key}) : super(key: key);

  @override
  State<ContractReviewScreen> createState() => _ContractReviewScreenState();
}

class _ContractReviewScreenState extends State<ContractReviewScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes Contrats'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrats Proposés'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('contrats_numeriques')
            .where('conducteurId', isEqualTo: user.uid)
            .where('statut', whereIn: [
              ContractStatus.propose.value,
              ContractStatus.enAttenteSignature.value,
              ContractStatus.enAttentePaiement.value,
            ])
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
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final contractData = contracts[index].data() as Map<String, dynamic>;
              final contractId = contracts[index].id;
              final contract = DigitalContract.fromFirestore(contracts[index]);
              
              return _buildContractCard(contract);
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
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun contrat en attente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos propositions de contrat apparaîtront ici',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(DigitalContract contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: contract.statut.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: contract.statut.color),
                  ),
                  child: Text(
                    contract.statut.displayName,
                    style: TextStyle(
                      color: contract.statut.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'N° ${contract.numeroContrat}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type de contrat et prime
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.typeContrat.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Du ${_formatDate(contract.dateDebut)} au ${_formatDate(contract.dateFin)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${contract.primeAnnuelle.toStringAsFixed(0)} DT',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'par an',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Garanties incluses
            _buildGarantiesSection(contract.garanties),
            const SizedBox(height: 16),

            // Informations de paiement
            if (contract.paiement.frequence != PaymentFrequency.annuel)
              _buildPaymentInfo(contract.paiement),

            const SizedBox(height: 20),

            // Boutons d'action
            _buildActionButtons(contract),
          ],
        ),
      ),
    );
  }

  Widget _buildGarantiesSection(List<Garantie> garanties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🛡️ Garanties incluses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: garanties.where((g) => g.incluse).map((garantie) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                garantie.nom,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(PaymentInfo paiement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement ${paiement.frequence.displayName.toLowerCase()}',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(paiement.montantTotal / paiement.frequence.installmentCount).toStringAsFixed(0)} DT × ${paiement.frequence.installmentCount} versements',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DigitalContract contract) {
    switch (contract.statut) {
      case ContractStatus.propose:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectContract(contract),
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Refuser'),
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
                onPressed: () => _acceptContract(contract),
                icon: const Icon(Icons.check),
                label: const Text('Accepter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );

      case ContractStatus.enAttenteSignature:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _signContract(contract),
            icon: const Icon(Icons.edit),
            label: const Text('Signer le contrat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case ContractStatus.enAttentePaiement:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _payContract(contract),
            icon: const Icon(Icons.payment),
            label: const Text('Procéder au paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _acceptContract(DigitalContract contract) async {
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('contrats_numeriques').doc(contract.id).update({
        'statut': ContractStatus.enAttenteSignature.value,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Contrat accepté! Vous pouvez maintenant le signer.');

    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'acceptation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectContract(DigitalContract contract) async {
    // Afficher dialog de confirmation avec raison
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('contrats_numeriques').doc(contract.id).update({
        'statut': ContractStatus.annule.value,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Contrat refusé.');

    } catch (e) {
      _showErrorSnackBar('Erreur lors du refus: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signContract(DigitalContract contract) async {
    // Ici on implémenterait la signature numérique
    // Pour l'instant, on simule
    setState(() => _isLoading = true);

    try {
      final signatureHash = DateTime.now().millisecondsSinceEpoch.toString();
      
      await _firestore.collection('contrats_numeriques').doc(contract.id).update({
        'statut': ContractStatus.enAttentePaiement.value,
        'signature': {
          'conducteurId': _auth.currentUser!.uid,
          'dateSignature': FieldValue.serverTimestamp(),
          'signatureHash': signatureHash,
          'ipAddress': '127.0.0.1', // À récupérer réellement
          'deviceInfo': 'Mobile App',
        },
        'signedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Contrat signé! Procédez maintenant au paiement.');

    } catch (e) {
      _showErrorSnackBar('Erreur lors de la signature: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _payContract(DigitalContract contract) async {
    // Ici on implémenterait le paiement
    // Pour l'instant, on simule un paiement réussi
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('contrats_numeriques').doc(contract.id).update({
        'statut': ContractStatus.actif.value,
        'paiement.statut': PaymentStatus.complet.value,
        'paiement.montantPaye': contract.primeAnnuelle,
        'paiement.datePremierPaiement': FieldValue.serverTimestamp(),
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le statut du véhicule
      await _firestore.collection('vehicules_en_attente').doc(contract.vehiculeId).update({
        'status': 'assure',
        'contractActivatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar('Paiement effectué! Votre véhicule est maintenant assuré.');

    } catch (e) {
      _showErrorSnackBar('Erreur lors du paiement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _showRejectDialog() async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser le contrat'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison du refus (optionnel)',
            hintText: 'Expliquez pourquoi vous refusez...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
