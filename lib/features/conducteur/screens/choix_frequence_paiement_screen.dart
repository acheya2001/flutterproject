import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/paiement_service.dart';

/// 💰 Écran de choix de fréquence de paiement
class ChoixFrequencePaiementScreen extends StatefulWidget {
  final String demandeId;
  final String conducteurId;
  final String numeroContrat;
  final Map<String, dynamic> demandeData;

  const ChoixFrequencePaiementScreen({
    Key? key,
    required this.demandeId,
    required this.conducteurId,
    required this.numeroContrat,
    required this.demandeData,
  }) : super(key: key);

  @override
  State<ChoixFrequencePaiementScreen> createState() => _ChoixFrequencePaiementScreenState();
}

class _ChoixFrequencePaiementScreenState extends State<ChoixFrequencePaiementScreen> {
  String _frequenceSelectionnee = 'annuel';
  bool _isLoading = false;

  // Tarifs configurables (à récupérer depuis Firestore en production)
  final Map<String, Map<String, dynamic>> _tarifs = {
    'annuel': {
      'montant': 1200.0,
      'economie': 0.0,
      'description': 'Paiement unique pour 12 mois',
      'avantages': ['Pas de frais supplémentaires', 'Couverture continue', 'Économique'],
    },
    'trimestriel': {
      'montant': 320.0,
      'economie': -80.0, // 320*4 = 1280 vs 1200
      'description': 'Paiement tous les 3 mois',
      'avantages': ['Flexibilité de paiement', 'Gestion budgétaire', 'Renouvellement automatique'],
    },
    'mensuel': {
      'montant': 110.0,
      'economie': -120.0, // 110*12 = 1320 vs 1200
      'description': 'Paiement mensuel',
      'avantages': ['Montant réduit par mois', 'Flexibilité maximale', 'Facilité budgétaire'],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Choisir la Fréquence de Paiement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête informatif
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                        'Votre Contrat est Prêt !',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contrat N° ${widget.numeroContrat}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisissez votre mode de paiement pour activer votre assurance.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Options de Paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 16),

            // Options de fréquence
            ...['annuel', 'trimestriel', 'mensuel'].map((frequence) => 
              _buildFrequenceOption(frequence)).toList(),

            const SizedBox(height: 32),

            // Résumé de la sélection
            _buildResume(),

            const SizedBox(height: 24),

            // Bouton de confirmation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmerChoix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirmer et Procéder au Paiement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Note informative
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Après confirmation, vous devrez vous présenter à l\'agence pour effectuer le paiement et activer votre contrat.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequenceOption(String frequence) {
    final tarif = _tarifs[frequence]!;
    final isSelected = _frequenceSelectionnee == frequence;
    final montant = tarif['montant'] as double;
    final economie = tarif['economie'] as double;
    final description = tarif['description'] as String;
    final avantages = tarif['avantages'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => setState(() => _frequenceSelectionnee = frequence),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : [
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
                  Radio<String>(
                    value: frequence,
                    groupValue: _frequenceSelectionnee,
                    onChanged: (value) => setState(() => _frequenceSelectionnee = value!),
                    activeColor: const Color(0xFF3B82F6),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getFrequenceLabel(frequence),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            if (economie < 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${(-economie).toStringAsFixed(0)} DT/an',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (economie == 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'RECOMMANDÉ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${montant.toStringAsFixed(0)} DT',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      Text(
                        _getFrequenceSubtitle(frequence),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Avantages
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: avantages.map((avantage) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    avantage,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? const Color(0xFF3B82F6) : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResume() {
    final tarif = _tarifs[_frequenceSelectionnee]!;
    final montant = tarif['montant'] as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé de votre choix',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fréquence de paiement:'),
              Text(
                _getFrequenceLabel(_frequenceSelectionnee),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant par paiement:'),
              Text(
                '${montant.toStringAsFixed(0)} DT',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFrequenceLabel(String frequence) {
    switch (frequence) {
      case 'annuel':
        return 'Paiement Annuel';
      case 'trimestriel':
        return 'Paiement Trimestriel';
      case 'mensuel':
        return 'Paiement Mensuel';
      default:
        return frequence;
    }
  }

  String _getFrequenceSubtitle(String frequence) {
    switch (frequence) {
      case 'annuel':
        return 'par an';
      case 'trimestriel':
        return 'tous les 3 mois';
      case 'mensuel':
        return 'par mois';
      default:
        return '';
    }
  }

  Future<void> _confirmerChoix() async {
    setState(() => _isLoading = true);

    try {
      final tarif = _tarifs[_frequenceSelectionnee]!;
      final montant = tarif['montant'] as double;

      // Mettre à jour la demande avec la fréquence choisie
      await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .doc(widget.demandeId)
          .update({
        'frequencePaiement': _frequenceSelectionnee,
        'montantPaiement': montant,
        'dateChoixPaiement': FieldValue.serverTimestamp(),
        'statut': 'frequence_choisie', // Nouveau statut
      });

      // Créer le premier paiement
      final paiementId = await PaiementService.creerPremierPaiement(
        conducteurId: widget.conducteurId,
        demandeId: widget.demandeId,
        numeroContrat: widget.numeroContrat,
        montant: montant,
        frequencePaiement: _frequenceSelectionnee,
      );

      if (paiementId != null) {
        // Mettre à jour avec l'ID du paiement
        await FirebaseFirestore.instance
            .collection('demandes_contrats')
            .doc(widget.demandeId)
            .update({
          'paiementId': paiementId,
        });

        // Créer notification pour le conducteur
        await FirebaseFirestore.instance.collection('notifications').add({
          'conducteurId': widget.conducteurId,
          'type': 'paiement_configure',
          'titre': 'Paiement Configuré',
          'message': 'Votre mode de paiement ${_getFrequenceLabel(_frequenceSelectionnee).toLowerCase()} a été configuré. Présentez-vous à l\'agence pour effectuer le premier paiement de ${montant.toStringAsFixed(0)} DT.',
          'demandeId': widget.demandeId,
          'paiementId': paiementId,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'priorite': 'haute',
        });

        // Notification pour l'agent
        await FirebaseFirestore.instance.collection('notifications').add({
          'agentId': widget.demandeData['agentId'],
          'type': 'frequence_choisie',
          'titre': 'Fréquence de Paiement Choisie',
          'message': 'Le conducteur ${widget.demandeData['prenom']} ${widget.demandeData['nom']} a choisi un paiement ${_getFrequenceLabel(_frequenceSelectionnee).toLowerCase()} (${montant.toStringAsFixed(0)} DT). Prêt pour encaissement.',
          'demandeId': widget.demandeId,
          'paiementId': paiementId,
          'dateCreation': FieldValue.serverTimestamp(),
          'lu': false,
          'priorite': 'normale',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fréquence de paiement configurée ! Rendez-vous à l\'agence pour payer.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      } else {
        throw Exception('Erreur lors de la création du paiement');
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
