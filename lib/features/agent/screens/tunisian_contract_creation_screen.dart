import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/tunisian_insurance_models.dart';
import '../../../services/tunisian_insurance_calculator.dart';
import '../../../services/tunisian_payment_service.dart';
import '../../../services/tunisian_documents_service.dart';

/// 🏢 Écran de création de contrat d'assurance tunisien complet
class TunisianContractCreationScreen extends StatefulWidget {
  final String vehiculeId;
  final Map<String, dynamic> vehiculeData;
  final String agentId;
  final String agenceId;

  const TunisianContractCreationScreen({
    Key? key,
    required this.vehiculeId,
    required this.vehiculeData,
    required this.agentId,
    required this.agenceId,
  }) : super(key: key);

  @override
  State<TunisianContractCreationScreen> createState() => _TunisianContractCreationScreenState();
}

class _TunisianContractCreationScreenState extends State<TunisianContractCreationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs pour les formulaires
  final _cinController = TextEditingController();
  final _permisController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  // Données du contrat
  String _typeCouverture = 'responsabilite_civile';
  String _zoneGeographique = 'tunis';
  String _niveauAntecedents = 'aucun';
  int _ageConducteur = 30;
  List<String> _optionsSelectionnees = [];
  
  // Données de paiement
  TypePaiement _typePaiement = TypePaiement.especes;
  FrequencePaiement _frequencePaiement = FrequencePaiement.annuel;
  
  // Résultats de calcul
  Map<String, dynamic>? _calculPrime;
  Map<String, dynamic>? _simulationOptions;

  @override
  void initState() {
    super.initState();
    _calculerPrimeInitiale();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Création Contrat d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),
      ),
      body: Column(
        children: [
          // Indicateur d'étapes
          _buildStepIndicator(),
          
          // Contenu principal
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildStep1VerificationDocuments(),
                _buildStep2CalculPrime(),
                _buildStep3ChoixCouverture(),
                _buildStep4Paiement(),
                _buildStep5Finalisation(),
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  /// 📊 Indicateur d'étapes
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepCircle(0, '1', 'Vérification'),
          _buildStepLine(0),
          _buildStepCircle(1, '2', 'Calcul'),
          _buildStepLine(1),
          _buildStepCircle(2, '3', 'Couverture'),
          _buildStepLine(2),
          _buildStepCircle(3, '4', 'Paiement'),
          _buildStepLine(3),
          _buildStepCircle(4, '5', 'Finalisation'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String number, String label) {
    bool isActive = step <= _currentStep;
    bool isCurrent = step == _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
              border: isCurrent ? Border.all(color: Colors.blue.shade800, width: 2) : null,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade600,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = step < _currentStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
      ),
    );
  }

  /// 📋 Étape 1: Vérification des documents
  Widget _buildStep1VerificationDocuments() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔍 Vérification des Documents'),
          const SizedBox(height: 16),
          
          // Informations véhicule (lecture seule)
          _buildVehicleInfoCard(),
          const SizedBox(height: 16),
          
          // Formulaire conducteur
          _buildConducteurForm(),
          const SizedBox(height: 16),
          
          // Checklist documents
          _buildDocumentsChecklist(),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚗 Informations Véhicule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Immatriculation', widget.vehiculeData['numeroImmatriculation'] ?? ''),
            _buildInfoRow('Marque', widget.vehiculeData['marque'] ?? ''),
            _buildInfoRow('Modèle', widget.vehiculeData['modele'] ?? ''),
            _buildInfoRow('Année', widget.vehiculeData['annee']?.toString() ?? ''),
            _buildInfoRow('Puissance Fiscale', '${widget.vehiculeData['puissanceFiscale'] ?? 0} CV'),
          ],
        ),
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
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConducteurForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👤 Informations Conducteur',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _cinController,
              decoration: const InputDecoration(
                labelText: 'Numéro CIN *',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _permisController,
              decoration: const InputDecoration(
                labelText: 'Numéro Permis de Conduire *',
                prefixIcon: Icon(Icons.drive_eta),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Âge du conducteur
            Row(
              children: [
                const Text('Âge du conducteur: '),
                Expanded(
                  child: Slider(
                    value: _ageConducteur.toDouble(),
                    min: 18,
                    max: 80,
                    divisions: 62,
                    label: '$_ageConducteur ans',
                    onChanged: (value) {
                      if (mounted) setState(() {
                        _ageConducteur = value.round();
                      });
                      _calculerPrimeInitiale();
                    },
                  ),
                ),
                Text('$_ageConducteur ans'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsChecklist() {
    List<Map<String, dynamic>> documents = [
      {'nom': 'Carte d\'identité nationale (CIN)', 'verifie': false},
      {'nom': 'Permis de conduire valide', 'verifie': false},
      {'nom': 'Carte grise du véhicule', 'verifie': false},
      {'nom': 'Contrôle technique (si requis)', 'verifie': false},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📄 Vérification Documents',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ...documents.map((doc) => CheckboxListTile(
              title: Text(doc['nom']),
              value: doc['verifie'],
              onChanged: (value) {
                if (mounted) setState(() {
                  doc['verifie'] = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            )),
          ],
        ),
      ),
    );
  }

  /// 💰 Calculer la prime initiale
  void _calculerPrimeInitiale() {
    if (mounted) setState(() {
      _calculPrime = TunisianInsuranceCalculator.calculerPrime(
        typeVehicule: widget.vehiculeData['typeVehicule'] ?? 'voiture',
        puissanceFiscale: widget.vehiculeData['puissanceFiscale'] ?? 5,
        ageConducteur: _ageConducteur,
        niveauAntecedents: _niveauAntecedents,
        typeCouverture: _typeCouverture,
        zoneGeographique: _zoneGeographique,
        anneeVehicule: widget.vehiculeData['annee'] ?? DateTime.now().year,
        optionsSupplementaires: _optionsSelectionnees,
      );
      
      _simulationOptions = TunisianInsuranceCalculator.simulerOptions(
        typeVehicule: widget.vehiculeData['typeVehicule'] ?? 'voiture',
        puissanceFiscale: widget.vehiculeData['puissanceFiscale'] ?? 5,
        ageConducteur: _ageConducteur,
        niveauAntecedents: _niveauAntecedents,
        zoneGeographique: _zoneGeographique,
        anneeVehicule: widget.vehiculeData['annee'] ?? DateTime.now().year,
      );
    });
  }

  /// 📊 Étape 2: Calcul de prime
  Widget _buildStep2CalculPrime() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('💰 Calcul de la Prime d\'Assurance'),
          const SizedBox(height: 16),
          
          // Paramètres de calcul
          _buildCalculParametres(),
          const SizedBox(height: 16),
          
          // Résultat du calcul
          if (_calculPrime != null) _buildCalculResult(),
          const SizedBox(height: 16),
          
          // Simulation des options
          if (_simulationOptions != null) _buildSimulationOptions(),
        ],
      ),
    );
  }

  Widget _buildCalculParametres() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ Paramètres de Calcul',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            // Zone géographique
            DropdownButtonFormField<String>(
              value: _zoneGeographique,
              decoration: const InputDecoration(
                labelText: 'Zone Géographique',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'tunis', child: Text('Grand Tunis')),
                DropdownMenuItem(value: 'sfax', child: Text('Sfax')),
                DropdownMenuItem(value: 'sousse', child: Text('Sousse')),
                DropdownMenuItem(value: 'gabes', child: Text('Gabès')),
                DropdownMenuItem(value: 'autre', child: Text('Autre ville')),
              ],
              onChanged: (value) {
                if (mounted) setState(() {
                  _zoneGeographique = value!;
                });
                _calculerPrimeInitiale();
              },
            ),
            const SizedBox(height: 12),
            
            // Antécédents
            DropdownButtonFormField<String>(
              value: _niveauAntecedents,
              decoration: const InputDecoration(
                labelText: 'Antécédents du Conducteur',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'aucun', child: Text('Aucun accident')),
                DropdownMenuItem(value: 'leger', child: Text('1 accident léger')),
                DropdownMenuItem(value: 'moyen', child: Text('2-3 accidents')),
                DropdownMenuItem(value: 'lourd', child: Text('4+ accidents')),
              ],
              onChanged: (value) {
                if (mounted) setState(() {
                  _niveauAntecedents = value!;
                });
                _calculerPrimeInitiale();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Résultat du Calcul',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prime de base:', style: TextStyle(fontSize: 16)),
                      Text('${_calculPrime!['primeBase']} TND', 
                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Taxes et frais:', style: TextStyle(fontSize: 16)),
                      Text('${_calculPrime!['taxes']} TND', 
                           style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL ANNUEL:', 
                                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${_calculPrime!['primeAnnuelle']} TND', 
                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Options de paiement
            Text('💳 Options de Paiement:', 
                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption('Mensuel', '${_calculPrime!['paiementMensuel']} TND/mois'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPaymentOption('Trimestriel', '${_calculPrime!['paiementTrimestriel']} TND/trim'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption('Semestriel', '${_calculPrime!['paiementSemestriel']} TND/sem'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPaymentOption('Annuel', '${_calculPrime!['primeAnnuelle']} TND/an'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(amount, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSimulationOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔄 Comparaison des Couvertures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._simulationOptions!.entries.map((entry) {
              String type = entry.key;
              Map<String, dynamic> data = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type == _typeCouverture ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: type == _typeCouverture ? Colors.blue.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: type,
                      groupValue: _typeCouverture,
                      onChanged: (value) {
                        if (mounted) setState(() {
                          _typeCouverture = value!;
                        });
                        _calculerPrimeInitiale();
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTypeCouvertureLabel(type),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${data['primeAnnuelle']} TND/an',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getTypeCouvertureLabel(String type) {
    switch (type) {
      case 'responsabilite_civile': return 'Responsabilité Civile';
      case 'tiers_collision': return 'Tiers + Collision';
      case 'vol_incendie': return 'Vol + Incendie';
      case 'tous_risques': return 'Tous Risques';
      case 'tous_risques_premium': return 'Tous Risques Premium';
      default: return type;
    }
  }

  /// 🛡️ Étape 3: Choix de couverture
  Widget _buildStep3ChoixCouverture() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🛡️ Choix de la Couverture'),
          const SizedBox(height: 16),
          
          // Garanties incluses
          _buildGarantiesIncluses(),
          const SizedBox(height: 16),
          
          // Options supplémentaires
          _buildOptionsSupplementaires(),
        ],
      ),
    );
  }

  Widget _buildGarantiesIncluses() {
    List<Map<String, dynamic>> garanties = TunisianInsuranceCalculator.getGarantiesDisponibles(_typeCouverture);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✅ Garanties Incluses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            ...garanties.map((garantie) => ListTile(
              leading: Icon(
                garantie['obligatoire'] ? Icons.check_circle : Icons.check_circle_outline,
                color: garantie['obligatoire'] ? Colors.green : Colors.blue,
              ),
              title: Text(garantie['nom']),
              subtitle: Text(garantie['description']),
              trailing: garantie['obligatoire'] 
                  ? const Chip(
                      label: Text('Obligatoire', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  : null,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSupplementaires() {
    List<Map<String, dynamic>> options = [
      {'nom': 'bris_de_glace', 'label': 'Bris de Glace', 'description': 'Pare-brise et vitres'},
      {'nom': 'assistance_depannage', 'label': 'Assistance Dépannage', 'description': '24h/24, 7j/7'},
      {'nom': 'vehicule_remplacement', 'label': 'Véhicule de Remplacement', 'description': 'En cas de sinistre'},
      {'nom': 'protection_juridique', 'label': 'Protection Juridique', 'description': 'Assistance juridique'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '➕ Options Supplémentaires',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            ...options.map((option) => CheckboxListTile(
              title: Text(option['label']),
              subtitle: Text(option['description']),
              value: _optionsSelectionnees.contains(option['nom']),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _optionsSelectionnees.add(option['nom']);
                  } else {
                    _optionsSelectionnees.remove(option['nom']);
                  }
                });
                _calculerPrimeInitiale();
              },
            )),
          ],
        ),
      ),
    );
  }

  /// 💳 Étape 4: Paiement
  Widget _buildStep4Paiement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('💳 Paiement de la Prime'),
          const SizedBox(height: 16),
          
          // Récapitulatif du montant
          _buildRecapitulatifMontant(),
          const SizedBox(height: 16),
          
          // Choix du type de paiement
          _buildChoixTypePaiement(),
          const SizedBox(height: 16),
          
          // Choix de la fréquence
          _buildChoixFrequencePaiement(),
          const SizedBox(height: 16),
          
          // Détails du paiement
          _buildDetailsPaiement(),
        ],
      ),
    );
  }

  Widget _buildRecapitulatifMontant() {
    if (_calculPrime == null) return const SizedBox();
    
    Map<String, dynamic> montantAvecFrais = TunisianPaymentService.calculerMontantAvecFrais(
      montantBase: _calculPrime!['primeAnnuelle'].toDouble(),
      frequence: _frequencePaiement,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💰 Récapitulatif du Montant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildMontantRow('Prime de base', '${_calculPrime!['primeBase']} TND'),
            _buildMontantRow('Options', '${_calculPrime!['coutOptions']} TND'),
            _buildMontantRow('Taxes', '${_calculPrime!['taxes']} TND'),
            if (montantAvecFrais['frais'] > 0)
              _buildMontantRow('Frais de fractionnement', '${montantAvecFrais['frais'].round()} TND'),
            const Divider(),
            _buildMontantRow(
              'TOTAL À PAYER',
              '${montantAvecFrais['montantTotal'].round()} TND',
              isTotal: true,
            ),
            if (_frequencePaiement != FrequencePaiement.annuel)
              _buildMontantRow(
                'Par ${_frequencePaiement.label.toLowerCase()}',
                '${montantAvecFrais['montantParPaiement'].round()} TND',
                isHighlight: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMontantRow(String label, String montant, {bool isTotal = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal || isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.blue.shade700 : null,
            ),
          ),
          Text(
            montant,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal || isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green.shade700 : (isHighlight ? Colors.blue.shade700 : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoixTypePaiement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '💳 Mode de Paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            ...TypePaiement.values.map((type) => RadioListTile<TypePaiement>(
              title: Text(type.label),
              value: type,
              groupValue: _typePaiement,
              onChanged: (value) {
                if (mounted) setState(() {
                  _typePaiement = value!;
                });
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildChoixFrequencePaiement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Fréquence de Paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            ...FrequencePaiement.values.map((freq) {
              String fraisText = freq.frais > 0 ? ' (+${(freq.frais * 100).round()}% de frais)' : '';
              return RadioListTile<FrequencePaiement>(
                title: Text('${freq.label}$fraisText'),
                value: freq,
                groupValue: _frequencePaiement,
                onChanged: (value) {
                  if (mounted) setState(() {
                    _frequencePaiement = value!;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPaiement() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📝 Détails du Paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            // Formulaire selon le type de paiement
            _buildPaiementForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaiementForm() {
    switch (_typePaiement) {
      case TypePaiement.carteBancaire:
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro de carte',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'MM/AA',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        );
      
      case TypePaiement.cheque:
        return Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Numéro de chèque',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Banque émettrice',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      
      case TypePaiement.mobile:
        return TextFormField(
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        );
      
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.green.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Paiement en espèces à effectuer au moment de la signature du contrat.'),
              ),
            ],
          ),
        );
    }
  }

  /// ✅ Étape 5: Finalisation
  Widget _buildStep5Finalisation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('✅ Finalisation du Contrat'),
          const SizedBox(height: 16),
          
          // Récapitulatif complet
          _buildRecapitulatifComplet(),
          const SizedBox(height: 16),
          
          // Bouton de création
          _buildBoutonCreation(),
        ],
      ),
    );
  }

  Widget _buildRecapitulatifComplet() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Récapitulatif Complet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildRecapSection('Véhicule', [
              '${widget.vehiculeData['marque']} ${widget.vehiculeData['modele']}',
              'Immatriculation: ${widget.vehiculeData['numeroImmatriculation']}',
              'Année: ${widget.vehiculeData['annee']}',
            ]),
            
            _buildRecapSection('Conducteur', [
              'CIN: ${_cinController.text}',
              'Permis: ${_permisController.text}',
              'Téléphone: ${_telephoneController.text}',
            ]),
            
            _buildRecapSection('Couverture', [
              _getTypeCouvertureLabel(_typeCouverture),
              'Prime: ${_calculPrime?['primeAnnuelle']} TND/an',
              'Franchise: ${_calculPrime?['franchise']} TND',
            ]),
            
            _buildRecapSection('Paiement', [
              _typePaiement.label,
              _frequencePaiement.label,
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildRecapSection(String titre, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 2),
          child: Text('• $item', style: const TextStyle(fontSize: 13)),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBoutonCreation() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _creerContrat,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                '✅ CRÉER LE CONTRAT ET ENCAISSER',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  /// 🔧 Méthodes utilitaires
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          if (_currentStep < 4)
            Expanded(
              child: ElevatedButton(
                onPressed: _canGoNext() ? () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                child: const Text('Suivant'),
              ),
            ),
        ],
      ),
    );
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0:
        return _cinController.text.isNotEmpty && 
               _permisController.text.isNotEmpty && 
               _telephoneController.text.isNotEmpty;
      case 1:
        return _calculPrime != null;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  /// 🎯 Créer le contrat complet
  Future<void> _creerContrat() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implémenter la création complète du contrat
      // 1. Créer le contrat dans Firestore
      // 2. Traiter le paiement
      // 3. Générer les documents (police, quittance, macaron)
      // 4. Mettre à jour le statut du véhicule
      
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contrat créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cinController.dispose();
    _permisController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }
}

