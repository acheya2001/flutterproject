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
      'montant': 850.0,
      'economie': 0.0,
      'description': 'Paiement unique annuel',
      'avantages': ['Meilleur prix', 'Sans frais', 'Économique'],
    },
    'trimestriel': {
      'montant': 230.0,
      'economie': -70.0, // 230*4 = 920 vs 850
      'description': 'Paiement tous les 3 mois',
      'avantages': ['Flexibilité', 'Gestion facile', 'Renouvellement auto'],
    },
    'mensuel': {
      'montant': 80.0,
      'economie': -110.0, // 80*12 = 960 vs 850
      'description': 'Paiement mensuel',
      'avantages': ['Petit montant', 'Très flexible', 'Budget maîtrisé'],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // AppBar moderne avec gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFF667EEA),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Finaliser votre',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Contrat d\'Assurance',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Contrat N° ${widget.numeroContrat}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message d'encouragement
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Félicitations !',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Votre dossier est validé. Choisissez votre mode de paiement pour activer votre assurance.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Titre section
                  const Text(
                    'Choisissez votre fréquence de paiement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez l\'option qui convient le mieux à votre budget',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options de paiement redesignées
                  ...['annuel', 'trimestriel', 'mensuel'].map((frequence) =>
                    _buildModernFrequenceOption(frequence)).toList(),

                  const SizedBox(height: 32),

                  // Résumé moderne
                  _buildModernResume(),

                  const SizedBox(height: 32),

                  // Bouton de confirmation moderne
                  _buildModernConfirmButton(),

                  const SizedBox(height: 24),

                  // Informations importantes
                  _buildImportantInfo(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFrequenceOption(String frequence) {
    final tarif = _tarifs[frequence]!;
    final isSelected = _frequenceSelectionnee == frequence;
    final montant = tarif['montant'] as double;
    final economie = tarif['economie'] as double;
    final description = tarif['description'] as String;
    final avantages = tarif['avantages'] as List<String>;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        elevation: isSelected ? 8 : 2,
        borderRadius: BorderRadius.circular(20),
        shadowColor: isSelected ? const Color(0xFF667EEA).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () => setState(() => _frequenceSelectionnee = frequence),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isSelected ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ) : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icône de sélection moderne
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: isSelected ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFF667EEA),
                      ) : null,
                    ),
                    const SizedBox(width: 16),

                    // Titre et badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFrequenceLabel(frequence),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (economie == 0 || economie < 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : (economie == 0 ? Colors.green[100] : Colors.orange[100]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    economie == 0
                                        ? 'RECOMMANDÉ'
                                        : '+${(-economie).toStringAsFixed(0)} DT/an',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? Colors.white
                                          : (economie == 0 ? Colors.green[700] : Colors.orange[700]),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Prix
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${montant.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF667EEA),
                          ),
                        ),
                        Text(
                          'DT ${_getFrequenceSubtitle(frequence)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Avantages avec design moderne
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: avantages.map((avantage) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF667EEA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: isSelected ? Colors.white : const Color(0xFF667EEA),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            avantage,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white : const Color(0xFF667EEA),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernResume() {
    final tarif = _tarifs[_frequenceSelectionnee]!;
    final montant = tarif['montant'] as double;
    final economie = tarif['economie'] as double;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF667EEA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Résumé de votre sélection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mode de paiement:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      _getFrequenceLabel(_frequenceSelectionnee),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant à payer:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      '${montant.toStringAsFixed(0)} DT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                  ],
                ),
                if (economie != 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Coût annuel total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${(montant * (_frequenceSelectionnee == 'annuel' ? 1 : _frequenceSelectionnee == 'trimestriel' ? 4 : 12)).toStringAsFixed(0)} DT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: economie < 0 ? Colors.orange[700] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernConfirmButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _confirmerChoix,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Traitement...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Confirmer le Paiement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImportantInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Prochaines étapes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoStep(
                '1',
                'Confirmation',
                'Votre choix sera enregistré dans notre système',
                Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
              _buildInfoStep(
                '2',
                'Rendez-vous en agence',
                'Présentez-vous avec vos documents pour effectuer le paiement',
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _buildInfoStep(
                '3',
                'Activation immédiate',
                'Votre contrat sera activé dès réception du paiement',
                Icons.verified_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vos données sont sécurisées et votre contrat sera valide dès le premier paiement.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoStep(String number, String title, String description, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          icon,
          color: Colors.blue[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ],
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
