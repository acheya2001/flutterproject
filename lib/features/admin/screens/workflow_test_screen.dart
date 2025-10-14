import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../services/workflow_test_service.dart';
import '../../../services/test_envoi_pdf_service.dart';

/// 🧪 Écran de test du workflow complet sinistre-expert
class WorkflowTestScreen extends StatefulWidget {
  const WorkflowTestScreen({Key? key}) : super(key: key);

  @override
  State<WorkflowTestScreen> createState() => _WorkflowTestScreenState();
}

class _WorkflowTestScreenState extends State<WorkflowTestScreen> {
  bool _isRunningTest = false;
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _testReport;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _loadTestReport();
    }
  }

  /// 📊 Charger le rapport de test
  Future<void> _loadTestReport() async {
    try {
      final report = await WorkflowTestService.getTestReport();
      setState(() => _testReport = report);
    } catch (e) {
      debugPrint('[WORKFLOW_TEST_SCREEN] ❌ Erreur chargement rapport: $e');
    }
  }

  /// 🧪 Lancer le test complet
  Future<void> _runCompleteTest() async {
    if (!kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tests disponibles uniquement en mode debug'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isRunningTest = true;
      _testResults = null;
    });

    try {
      final results = await WorkflowTestService.testCompleteWorkflow();
      setState(() => _testResults = results);

      if (results['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test du workflow complet réussi !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test échoué: ${results['errors'].join(', ')}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Recharger le rapport
      await _loadTestReport();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRunningTest = false);
    }
  }

  /// 📄 Tester l'envoi de PDF
  Future<void> _testEnvoiPdf() async {
    if (!kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tests disponibles uniquement en mode debug'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isRunningTest = true);

    try {
      final results = await TestEnvoiPdfService.testEnvoiPdfComplet();

      if (results['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test envoi PDF réussi !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test envoi PDF échoué: ${results['errors'].join(', ')}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Mettre à jour les résultats pour affichage
      setState(() => _testResults = results);
      await _loadTestReport();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur test PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isRunningTest = false);
    }
  }

  /// 🧹 Nettoyer les données de test
  Future<void> _cleanupTestData() async {
    if (!kDebugMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les données de test'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les données de test ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await WorkflowTestService.cleanupTestData();
        await TestEnvoiPdfService.cleanupTestData();
        await _loadTestReport();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données de test supprimées'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur nettoyage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tests Workflow'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Tests disponibles uniquement en mode debug',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tests Workflow Sinistre-Expert'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTestReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestControls(),
            const SizedBox(height: 24),
            if (_testResults != null) _buildTestResults(),
            if (_testResults != null) const SizedBox(height: 24),
            if (_testReport != null) _buildTestReport(),
          ],
        ),
      ),
    );
  }

  /// 🎮 Contrôles de test
  Widget _buildTestControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Contrôles de Test',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Testez le workflow complet : Admin Agence crée Expert → Conducteur déclare Sinistre → Agent assigne Expert → Expert traite → Conducteur suit.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunningTest ? null : _runCompleteTest,
                  icon: _isRunningTest 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunningTest ? 'Test en cours...' : 'Lancer Test Complet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _testEnvoiPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Test PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _cleanupTestData,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Nettoyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📊 Résultats du test
  Widget _buildTestResults() {
    final results = _testResults!;
    final success = results['success'] as bool;
    final steps = results['steps'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                success ? 'Test Réussi' : 'Test Échoué',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: success ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.entries.map((entry) {
            final stepName = entry.key;
            final stepData = entry.value as Map<String, dynamic>;
            final stepSuccess = stepData['success'] as bool;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    stepSuccess ? Icons.check : Icons.close,
                    color: stepSuccess ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_getStepTitle(stepName)}: ${stepData['message']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (!success && results['errors'] != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Erreurs:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...(results['errors'] as List).map((error) => Text(
              '• $error',
              style: const TextStyle(fontSize: 14, color: Colors.red),
            )).toList(),
          ],
        ],
      ),
    );
  }

  /// 📋 Rapport des données de test
  Widget _buildTestReport() {
    final report = _testReport!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Données de Test Existantes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          ...report.entries.map((entry) {
            final collection = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final count = data['count'] as int;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: count > 0 ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$collection: $count documents',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 📝 Obtenir le titre de l'étape
  String _getStepTitle(String stepName) {
    switch (stepName) {
      case 'createTestData':
        return 'Création données test';
      case 'expertCreation':
        return 'Création expert';
      case 'sinistreDeclaration':
        return 'Déclaration sinistre';
      case 'expertAssignment':
        return 'Assignation expert';
      case 'missionStart':
        return 'Démarrage mission';
      case 'missionCompletion':
        return 'Finalisation mission';
      case 'conducteurTracking':
        return 'Suivi conducteur';
      default:
        return stepName;
    }
  }
}
