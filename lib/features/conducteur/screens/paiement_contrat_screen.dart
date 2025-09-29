import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaiementContratScreen extends StatefulWidget {
  final String demandeId;
  final Map<String, dynamic> demandeData;

  const PaiementContratScreen({
    Key? key,
    required this.demandeId,
    required this.demandeData,
  }) : super(key: key);

  @override
  State<PaiementContratScreen> createState() => _PaiementContratScreenState();
}

class _PaiementContratScreenState extends State<PaiementContratScreen> {
  String? _selectedFrequence;
  
  final Map<String, Map<String, dynamic>> _frequencesPaiement = {
    'annuel': {
      'label': 'Paiement Annuel',
      'description': 'Une seule fois par an',
      'reduction': 0.05, // 5% de réduction
      'icon': Icons.calendar_view_year,
    },
    'semestriel': {
      'label': 'Paiement Semestriel',
      'description': '2 fois par an',
      'reduction': 0.02, // 2% de réduction
      'icon': Icons.calendar_view_month,
    },
    'trimestriel': {
      'label': 'Paiement Trimestriel',
      'description': '4 fois par an',
      'reduction': 0.0, // Pas de réduction
      'icon': Icons.calendar_today,
    },
  };

  double get _montantBase {
    final formule = widget.demandeData['formuleAssurance'] ?? 'rc';
    switch (formule) {
      case 'rc':
        return 250.0;
      case 'rc_vol_incendie':
        return 450.0;
      case 'tous_risques':
        return 750.0;
      default:
        return 250.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('💳 Paiement du Contrat'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé du contrat
            _buildContractSummary(),
            
            const SizedBox(height: 24),
            
            // Options de paiement
            _buildPaymentOptions(),
            
            const SizedBox(height: 24),
            
            // Récapitulatif du paiement
            if (_selectedFrequence != null)
              _buildPaymentSummary(),
            
            const SizedBox(height: 32),
            
            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFrequence != null ? _confirmPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '🏢 Confirmer - Paiement en Agence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractSummary() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description, color: Colors.blue[700]),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '📋 Résumé du Contrat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSummaryRow('Véhicule', '${widget.demandeData['marque']} ${widget.demandeData['modele']}'),
          _buildSummaryRow('Immatriculation', widget.demandeData['immatriculation'] ?? 'N/A'),
          _buildSummaryRow('Formule', widget.demandeData['formuleAssuranceLabel'] ?? 'N/A'),
          _buildSummaryRow('Compagnie', widget.demandeData['compagnieNom'] ?? 'N/A'),
          _buildSummaryRow('Agence', widget.demandeData['agenceNom'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
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
          const Text(
            '💳 Choisissez votre fréquence de paiement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ..._frequencesPaiement.entries.map((entry) {
            final key = entry.key;
            final data = entry.value;
            final isSelected = _selectedFrequence == key;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (mounted) setState(() {
                    _selectedFrequence = key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green[400]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.green[700] : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        data['icon'] as IconData,
                        color: isSelected ? Colors.green[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isSelected ? Colors.green[700] : Colors.black87,
                              ),
                            ),
                            Text(
                              data['description'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((data['reduction'] as double) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${((data['reduction'] as double) * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final frequenceData = _frequencesPaiement[_selectedFrequence]!;
    final reduction = frequenceData['reduction'] as double;
    final montantAvecReduction = _montantBase * (1 - reduction);
    
    int nombrePaiements;
    switch (_selectedFrequence) {
      case 'annuel':
        nombrePaiements = 1;
        break;
      case 'semestriel':
        nombrePaiements = 2;
        break;
      case 'trimestriel':
        nombrePaiements = 4;
        break;
      default:
        nombrePaiements = 1;
    }
    
    final montantParPaiement = montantAvecReduction / nombrePaiements;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text(
                '💰 Récapitulatif du Paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSummaryRow('Montant de base', '${_montantBase.toStringAsFixed(0)} DT'),
          if (reduction > 0)
            _buildSummaryRow('Réduction', '-${(_montantBase * reduction).toStringAsFixed(0)} DT'),
          _buildSummaryRow('Total annuel', '${montantAvecReduction.toStringAsFixed(0)} DT'),
          
          const Divider(height: 24),
          
          _buildSummaryRow('Nombre de paiements', '$nombrePaiements'),
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  'Montant par paiement',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${montantParPaiement.toStringAsFixed(0)} DT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPayment() async {
    try {
      final frequenceData = _frequencesPaiement[_selectedFrequence]!;
      final reduction = frequenceData['reduction'] as double;
      final montantTotal = _montantBase * (1 - reduction);
      
      int nombrePaiements;
      switch (_selectedFrequence) {
        case 'annuel':
          nombrePaiements = 1;
          break;
        case 'semestriel':
          nombrePaiements = 2;
          break;
        case 'trimestriel':
          nombrePaiements = 4;
          break;
        default:
          nombrePaiements = 1;
      }

      // Mettre à jour la demande avec les informations de paiement
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(widget.demandeId)
          .update({
        'statut': 'en_attente_paiement',
        'frequencePaiement': _selectedFrequence,
        'montantTotal': montantTotal,
        'montantParPaiement': montantTotal / nombrePaiements,
        'nombrePaiements': nombrePaiements,
        'datePaiementConfirme': FieldValue.serverTimestamp(),
      });

      // Créer notification pour l'agent
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'type': 'paiement_confirme',
        'titre': 'Paiement confirmé',
        'message': 'Le conducteur a confirmé le paiement pour la demande ${widget.demandeData['numero']}. Montant: ${(montantTotal / nombrePaiements).toStringAsFixed(0)} DT',
        'demandeId': widget.demandeId,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      // Créer notification pour le conducteur
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'conducteurId': widget.demandeData['conducteurId'],
        'conducteurEmail': widget.demandeData['email'],
        'type': 'paiement_requis',
        'titre': 'Paiement en agence requis',
        'message': 'Votre dossier est validé. Cliquez maintenant pour choisir votre fréquence de paiement et finaliser votre contrat.',
        'demandeId': widget.demandeId,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paiement confirmé ! Rendez-vous en agence pour finaliser.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

