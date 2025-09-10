import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/test_data_service.dart';
import '../../services/tunisian_insurance_calculator.dart';
import '../../services/tunisian_payment_service.dart';
import '../agent/screens/tunisian_agent_dashboard.dart';
import '../conducteur/screens/tunisian_conducteur_dashboard.dart';

/// 🧪 Dashboard de test pour le système d'assurance tunisien
class TestDashboardScreen extends StatefulWidget {
  const TestDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TestDashboardScreen> createState() => _TestDashboardScreenState();
}

class _TestDashboardScreenState extends State<TestDashboardScreen> {
  bool _isLoading = false;
  Map<String, String> _testDataIds = {};
  String _logOutput = '';

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mode Test')),
        body: const Center(
          child: Text(
            'Mode test disponible uniquement en debug',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '🧪 Test Dashboard - Assurance Tunisienne',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section données de test
            _buildTestDataSection(),
            const SizedBox(height: 20),
            
            // Section tests calculateur
            _buildCalculatorTestSection(),
            const SizedBox(height: 20),
            
            // Section tests paiement
            _buildPaymentTestSection(),
            const SizedBox(height: 20),
            
            // Section navigation
            _buildNavigationSection(),
            const SizedBox(height: 20),
            
            // Log de sortie
            _buildLogSection(),
          ],
        ),
      ),
    );
  }

  /// 📊 Section données de test
  Widget _buildTestDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Gestion des Données de Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateTestData,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Générer Données'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showTestDataStats,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Statistiques'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _cleanupTestData,
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Nettoyer Données de Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  /// 🧮 Section tests calculateur
  Widget _buildCalculatorTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧮 Tests Calculateur de Prime',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testBasicCalculation,
                    child: const Text('Test Calcul de Base'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testAgeComparison,
                    child: const Text('Test Âge Conducteur'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testCoverageComparison,
                    child: const Text('Test Couvertures'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testOptionsSimulation,
                    child: const Text('Test Simulation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 💳 Section tests paiement
  Widget _buildPaymentTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💳 Tests Service de Paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testPaymentCalculation,
                    child: const Text('Test Calcul Frais'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testPaymentFrequencies,
                    child: const Text('Test Fréquences'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🧭 Section navigation
  Widget _buildNavigationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🧭 Navigation vers les Interfaces',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAgentDashboard,
                    icon: const Icon(Icons.business_center),
                    label: const Text('Dashboard Agent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToConducteurDashboard,
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Dashboard Conducteur'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
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
  }

  /// 📝 Section log
  Widget _buildLogSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📝 Log de Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearLog,
                  child: const Text('Effacer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _logOutput.isEmpty ? 'Aucun log pour le moment...' : _logOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 Méthodes de test

  void _addLog(String message) {
    setState(() {
      _logOutput += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
  }

  void _clearLog() {
    if (mounted) setState(() {
      _logOutput = '';
    });
  }

  Future<void> _generateTestData() async {
    setState(() => _isLoading = true);
    _addLog('🧪 Début génération données de test...');
    
    try {
      _testDataIds = await TestDataService.createCompleteTestDataSet();
      _addLog('✅ Données de test générées avec succès !');
      _addLog('   Compagnie ID: ${_testDataIds['compagnieId']}');
      _addLog('   Agence ID: ${_testDataIds['agenceId']}');
      _addLog('   Agent ID: ${_testDataIds['agentId']}');
    } catch (e) {
      _addLog('❌ Erreur génération: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showTestDataStats() async {
    _addLog('📊 Affichage statistiques...');
    await TestDataService.showTestDataStats();
    _addLog('✅ Statistiques affichées dans la console');
  }

  Future<void> _cleanupTestData() async {
    setState(() => _isLoading = true);
    _addLog('🗑️ Nettoyage des données de test...');
    
    try {
      await TestDataService.cleanupTestData();
      _addLog('✅ Nettoyage terminé !');
      _testDataIds.clear();
    } catch (e) {
      _addLog('❌ Erreur nettoyage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _testBasicCalculation() {
    _addLog('🧮 Test calcul de base...');
    
    final result = TunisianInsuranceCalculator.calculerPrime(
      typeVehicule: 'voiture',
      puissanceFiscale: 6,
      ageConducteur: 30,
      niveauAntecedents: 'aucun',
      typeCouverture: 'responsabilite_civile',
      zoneGeographique: 'tunis',
      anneeVehicule: 2020,
    );
    
    _addLog('   Prime calculée: ${result['primeAnnuelle']} TND');
    _addLog('   Franchise: ${result['franchise']} TND');
    _addLog('✅ Test calcul de base réussi');
  }

  void _testAgeComparison() {
    _addLog('👤 Test comparaison âges...');
    
    final jeune = TunisianInsuranceCalculator.calculerPrime(
      typeVehicule: 'voiture',
      puissanceFiscale: 6,
      ageConducteur: 22,
      niveauAntecedents: 'aucun',
      typeCouverture: 'responsabilite_civile',
      zoneGeographique: 'tunis',
      anneeVehicule: 2020,
    );
    
    final adulte = TunisianInsuranceCalculator.calculerPrime(
      typeVehicule: 'voiture',
      puissanceFiscale: 6,
      ageConducteur: 35,
      niveauAntecedents: 'aucun',
      typeCouverture: 'responsabilite_civile',
      zoneGeographique: 'tunis',
      anneeVehicule: 2020,
    );
    
    _addLog('   Jeune (22 ans): ${jeune['primeAnnuelle']} TND');
    _addLog('   Adulte (35 ans): ${adulte['primeAnnuelle']} TND');
    _addLog('   Différence: ${jeune['primeAnnuelle'] - adulte['primeAnnuelle']} TND');
    _addLog('✅ Test âges réussi');
  }

  void _testCoverageComparison() {
    _addLog('🛡️ Test comparaison couvertures...');
    
    final rc = TunisianInsuranceCalculator.calculerPrime(
      typeVehicule: 'voiture',
      puissanceFiscale: 6,
      ageConducteur: 30,
      niveauAntecedents: 'aucun',
      typeCouverture: 'responsabilite_civile',
      zoneGeographique: 'tunis',
      anneeVehicule: 2020,
    );
    
    final tousRisques = TunisianInsuranceCalculator.calculerPrime(
      typeVehicule: 'voiture',
      puissanceFiscale: 6,
      ageConducteur: 30,
      niveauAntecedents: 'aucun',
      typeCouverture: 'tous_risques',
      zoneGeographique: 'tunis',
      anneeVehicule: 2020,
    );
    
    _addLog('   RC: ${rc['primeAnnuelle']} TND');
    _addLog('   Tous Risques: ${tousRisques['primeAnnuelle']} TND');
    _addLog('   Surcoût: ${tousRisques['primeAnnuelle'] - rc['primeAnnuelle']} TND');
    _addLog('✅ Test couvertures réussi');
  }

  void _testOptionsSimulation() {
    _addLog('🔄 Test simulation options...');
    
    final simulation = TunisianInsuranceCalculator.simulerOptions(
      typeVehicule: 'voiture',
      puissanceFiscale: 6,
      ageConducteur: 30,
      niveauAntecedents: 'aucun',
      zoneGeographique: 'tunis',
      anneeVehicule: 2020,
    );
    
    _addLog('   Options simulées: ${simulation.keys.length}');
    for (var entry in simulation.entries) {
      _addLog('   ${entry.key}: ${entry.value['primeAnnuelle']} TND');
    }
    _addLog('✅ Test simulation réussi');
  }

  void _testPaymentCalculation() {
    _addLog('💰 Test calcul frais paiement...');
    
    const montant = 500.0;
    
    final annuel = TunisianPaymentService.calculerMontantAvecFrais(
      montantBase: montant,
      frequence: FrequencePaiement.annuel,
    );
    
    final mensuel = TunisianPaymentService.calculerMontantAvecFrais(
      montantBase: montant,
      frequence: FrequencePaiement.mensuel,
    );
    
    _addLog('   Annuel: ${annuel['montantTotal']} TND (${annuel['frais']} TND frais)');
    _addLog('   Mensuel: ${mensuel['montantTotal']} TND (${mensuel['frais']} TND frais)');
    _addLog('   Économie annuelle: ${mensuel['montantTotal'] - annuel['montantTotal']} TND');
    _addLog('✅ Test calcul frais réussi');
  }

  void _testPaymentFrequencies() {
    _addLog('📅 Test fréquences paiement...');
    
    const montant = 600.0;
    final frequences = FrequencePaiement.values;
    
    for (var freq in frequences) {
      final result = TunisianPaymentService.calculerMontantAvecFrais(
        montantBase: montant,
        frequence: freq,
      );
      _addLog('   ${freq.label}: ${result['montantParPaiement']} TND x ${result['nbPaiements']}');
    }
    _addLog('✅ Test fréquences réussi');
  }

  void _navigateToAgentDashboard() {
    if (_testDataIds.isEmpty) {
      _addLog('❌ Générez d\'abord les données de test');
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TunisianAgentDashboard(
          agentId: _testDataIds['agentId']!,
          agenceId: _testDataIds['agenceId']!,
        ),
      ),
    );
  }

  void _navigateToConducteurDashboard() {
    if (_testDataIds.isEmpty) {
      _addLog('❌ Générez d\'abord les données de test');
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TunisianConducteurDashboard(
          conducteurId: _testDataIds['conducteurId']!,
        ),
      ),
    );
  }
}

