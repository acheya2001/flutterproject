import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RenouvellementContratScreen extends StatefulWidget {
  final String contratId;
  final Map<String, dynamic> contratData;

  const RenouvellementContratScreen({
    Key? key,
    required this.contratId,
    required this.contratData,
  }) : super(key: key);

  @override
  State<RenouvellementContratScreen> createState() => _RenouvellementContratScreenState();
}

class _RenouvellementContratScreenState extends State<RenouvellementContratScreen> {
  String? _nouvelleFormule;
  String? _nouvelleFrequence;
  bool _renouvellementAutomatique = false;
  bool _isProcessing = false;

  final Map<String, Map<String, dynamic>> _formulesAssurance = {
    'rc': {
      'label': 'Responsabilité Civile (RC)',
      'description': 'Couverture minimale obligatoire',
      'prix': 250.0,
    },
    'rc_vol_incendie': {
      'label': 'RC + Vol + Incendie',
      'description': 'RC + Protection vol et incendie',
      'prix': 450.0,
    },
    'tous_risques': {
      'label': 'Tous Risques',
      'description': 'Couverture complète',
      'prix': 750.0,
    },
  };

  final Map<String, Map<String, dynamic>> _frequencesPaiement = {
    'annuel': {
      'label': 'Paiement Annuel',
      'reduction': 0.05,
      'icon': Icons.calendar_view_year,
    },
    'semestriel': {
      'label': 'Paiement Semestriel',
      'reduction': 0.02,
      'icon': Icons.calendar_view_month,
    },
    'trimestriel': {
      'label': 'Paiement Trimestriel',
      'reduction': 0.0,
      'icon': Icons.calendar_today,
    },
  };

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs actuelles
    _nouvelleFormule = widget.contratData['formuleAssurance'];
    _nouvelleFrequence = widget.contratData['frequencePaiement'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('🔄 Renouvellement'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations du contrat actuel
            _buildCurrentContractInfo(),
            
            const SizedBox(height: 24),
            
            // Choix de la nouvelle formule
            _buildFormulaSelection(),
            
            const SizedBox(height: 24),
            
            // Choix de la fréquence de paiement
            _buildPaymentFrequencySelection(),
            
            const SizedBox(height: 24),
            
            // Options de renouvellement
            _buildRenewalOptions(),
            
            const SizedBox(height: 24),
            
            // Récapitulatif
            if (_nouvelleFormule != null && _nouvelleFrequence != null)
              _buildSummary(),
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentContractInfo() {
    final vehicule = widget.contratData['vehicule'] as Map<String, dynamic>? ?? {};
    final dateFin = widget.contratData['dateFin']?.toDate();
    final formuleActuelle = widget.contratData['formuleAssuranceLabel'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
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
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info, color: Colors.orange[700]),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '📋 Contrat Actuel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoRow('Véhicule', '${vehicule['marque']} ${vehicule['modele']} - ${vehicule['immatriculation']}'),
          _buildInfoRow('Formule actuelle', formuleActuelle),
          if (dateFin != null)
            _buildInfoRow('Expire le', _formatDate(dateFin)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildFormulaSelection() {
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
            '🛡️ Choisissez votre nouvelle formule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ..._formulesAssurance.entries.map((entry) {
            final key = entry.key;
            final data = entry.value;
            final isSelected = _nouvelleFormule == key;
            final isUpgrade = _isUpgrade(key);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (mounted) setState(() {
                    _nouvelleFormule = key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.blue[700] : Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['label'] as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelected ? Colors.blue[700] : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isUpgrade)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'UPGRADE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
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
                      Text(
                        '${(data['prix'] as double).toStringAsFixed(0)} DT/an',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue[700] : Colors.black87,
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

  Widget _buildPaymentFrequencySelection() {
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
            '💳 Fréquence de paiement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ..._frequencesPaiement.entries.map((entry) {
            final key = entry.key;
            final data = entry.value;
            final isSelected = _nouvelleFrequence == key;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  if (mounted) setState(() {
                    _nouvelleFrequence = key;
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
                        child: Text(
                          data['label'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected ? Colors.green[700] : Colors.black87,
                          ),
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

  Widget _buildRenewalOptions() {
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
            '⚙️ Options de renouvellement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Renouvellement automatique'),
            subtitle: const Text('Renouveler automatiquement chaque année'),
            value: _renouvellementAutomatique,
            onChanged: (value) {
              if (mounted) setState(() {
                _renouvellementAutomatique = value;
              });
            },
            activeColor: Colors.green[600],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final formuleData = _formulesAssurance[_nouvelleFormule]!;
    final frequenceData = _frequencesPaiement[_nouvelleFrequence]!;
    final prixBase = formuleData['prix'] as double;
    final reduction = frequenceData['reduction'] as double;
    final prixFinal = prixBase * (1 - reduction);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                '💰 Récapitulatif du Renouvellement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSummaryRow('Nouvelle formule', formuleData['label'] as String),
          _buildSummaryRow('Fréquence', frequenceData['label'] as String),
          _buildSummaryRow('Prix de base', '${prixBase.toStringAsFixed(0)} DT'),
          if (reduction > 0)
            _buildSummaryRow('Réduction', '-${(prixBase * reduction).toStringAsFixed(0)} DT'),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                'Total annuel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${prixFinal.toStringAsFixed(0)} DT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processRenewal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Traitement en cours...'),
                    ],
                  )
                : const Text(
                    '🔄 Renouveler le Contrat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ),
      ],
    );
  }

  bool _isUpgrade(String nouvelleFormule) {
    final formuleActuelle = widget.contratData['formuleAssurance'];
    final ordreFormules = ['rc', 'rc_vol_incendie', 'tous_risques'];
    
    final indexActuel = ordreFormules.indexOf(formuleActuelle);
    final indexNouveau = ordreFormules.indexOf(nouvelleFormule);
    
    return indexNouveau > indexActuel;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _processRenewal() async {
    if (mounted) setState(() {
      _isProcessing = true;
    });

    try {
      // Créer une nouvelle demande de renouvellement
      await FirebaseFirestore.instance.collection('demandes_renouvellement').add({
        'contratActuelId': widget.contratId,
        'conducteurId': widget.contratData['conducteurId'],
        'nouvelleFormule': _nouvelleFormule,
        'nouvelleFrequence': _nouvelleFrequence,
        'renouvellementAutomatique': _renouvellementAutomatique,
        'statut': 'en_attente_validation',
        'dateCreation': FieldValue.serverTimestamp(),
      });

      // Créer notification pour l'agent
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'demande_renouvellement',
        'titre': 'Demande de renouvellement',
        'message': 'Nouvelle demande de renouvellement pour le contrat ${widget.contratData['numeroContrat']}',
        'contratId': widget.contratId,
        'dateCreation': FieldValue.serverTimestamp(),
        'lu': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demande de renouvellement envoyée !'),
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
    } finally {
      if (mounted) setState(() {
        _isProcessing = false;
      });
    }
  }
}

