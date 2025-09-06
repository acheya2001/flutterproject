import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/paiement_model.dart';
import '../../../services/paiement_service.dart';

/// 💳 Écran de validation de paiement par l'agent
class ValidationPaiementScreen extends StatefulWidget {
  final PaiementModel paiement;
  final String agentId;

  const ValidationPaiementScreen({
    Key? key,
    required this.paiement,
    required this.agentId,
  }) : super(key: key);

  @override
  State<ValidationPaiementScreen> createState() => _ValidationPaiementScreenState();
}

class _ValidationPaiementScreenState extends State<ValidationPaiementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  String _modePaiementSelectionne = 'especes';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _modesPaiement = [
    {'value': 'especes', 'label': 'Espèces', 'icon': Icons.money},
    {'value': 'carte_bancaire', 'label': 'Carte Bancaire', 'icon': Icons.credit_card},
    {'value': 'cheque', 'label': 'Chèque', 'icon': Icons.receipt_long},
    {'value': 'virement', 'label': 'Virement', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    _montantController.text = widget.paiement.montant.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Validation de Paiement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations du paiement
              _buildPaiementInfo(),

              const SizedBox(height: 24),

              // Informations du conducteur
              _buildConducteurInfo(),

              const SizedBox(height: 24),

              // Formulaire de validation
              _buildValidationForm(),

              const SizedBox(height: 32),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaiementInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Paiement à Valider',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montant',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    widget.paiement.montantFormate,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Échéance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    _formatDate(widget.paiement.dateEcheance),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Fréquence: ${_getFrequenceLabel(widget.paiement.frequencePaiement)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConducteurInfo() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.paiement.conducteurId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final conducteurData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: Color(0xFF3B82F6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Informations Conducteur',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Nom', '${conducteurData['prenom'] ?? ''} ${conducteurData['nom'] ?? ''}'),
              _buildInfoRow('CIN', conducteurData['cin'] ?? 'N/A'),
              _buildInfoRow('Téléphone', conducteurData['telephone'] ?? 'N/A'),
              _buildInfoRow('Contrat', widget.paiement.numeroContrat),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValidationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 8),
              Text(
                'Validation du Paiement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Montant reçu
          TextFormField(
            controller: _montantController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant Reçu (DT)',
              prefixIcon: const Icon(Icons.euro),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez saisir le montant';
              }
              final montant = double.tryParse(value);
              if (montant == null || montant <= 0) {
                return 'Montant invalide';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Mode de paiement
          const Text(
            'Mode de Paiement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...(_modesPaiement.map((mode) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: RadioListTile<String>(
              value: mode['value'],
              groupValue: _modePaiementSelectionne,
              onChanged: (value) => setState(() => _modePaiementSelectionne = value!),
              title: Row(
                children: [
                  Icon(mode['icon'], size: 20, color: const Color(0xFF3B82F6)),
                  const SizedBox(width: 12),
                  Text(mode['label']),
                ],
              ),
              activeColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tileColor: _modePaiementSelectionne == mode['value'] 
                  ? const Color(0xFF3B82F6).withOpacity(0.1) 
                  : Colors.grey[50],
            ),
          ))).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _validerPaiement,
            icon: const Icon(Icons.check_circle),
            label: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Valider le Paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequenceLabel(String frequence) {
    switch (frequence) {
      case 'annuel':
        return 'Annuel';
      case 'trimestriel':
        return 'Trimestriel';
      case 'mensuel':
        return 'Mensuel';
      default:
        return frequence;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _validerPaiement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final montantRecu = double.parse(_montantController.text);

      final success = await PaiementService.validerPaiement(
        paiementId: widget.paiement.id,
        agentId: widget.agentId,
        modePaiement: _modePaiementSelectionne,
        montantRecu: montantRecu,
      );

      if (success) {
        // Créer notification pour le conducteur
        await FirebaseFirestore.instance.collection('notifications').add({
          'conducteurId': widget.paiement.conducteurId,
          'type': 'paiement_valide',
          'titre': 'Paiement Confirmé',
          'message': 'Votre paiement de ${montantRecu.toStringAsFixed(2)} DT a été confirmé. Votre contrat est maintenant actif.',
          'paiementId': widget.paiement.id,
          'numeroRecu': 'REC${DateTime.now().millisecondsSinceEpoch}',
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'priorite': 'haute',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement validé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception('Erreur lors de la validation');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
