import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/custom_app_bar.dart';
import '../database/services/firebase_data_organizer.dart';
import '../vehicule/services/vehicule_affectation_service.dart';
import '../vehicule/services/vehicule_recherche_service.dart';
import '../vehicule/models/vehicule_recherche_model.dart';

/// 🧪 Écran de test pour vérifier les fonctionnalités
class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  String _statusMessage = '';
  bool _isLoading = false;

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _testGenerateData() async {
    setState(() => _isLoading = true);
    _updateStatus('🚀 Génération des données de test...');

    try {
      await FirebaseDataOrganizer.generateCompleteDatabase();
      _updateStatus('✅ Données générées avec succès !');
    } catch (e) {
      _updateStatus('❌ Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testVehicleSearch() async {
    setState(() => _isLoading = true);
    _updateStatus('🔍 Test de recherche véhicule...');

    try {
      final criteres = CriteresRecherche(
        assurance: 'STAR',
        immatriculation: '123 TUN 456',
      );

      final resultats = await VehiculeRechercheService.rechercherVehicule(
        conducteurRechercheur: 'test_user',
        criteres: criteres,
      );

      _updateStatus('✅ Recherche terminée: ${resultats.length} résultats');
    } catch (e) {
      _updateStatus('❌ Erreur recherche: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testVehicleAffectation() async {
    setState(() => _isLoading = true);
    _updateStatus('🔗 Test d\'affectation véhicule...');

    try {
      final vehicules = await VehiculeAffectationService.getVehiculesConducteur('test@example.com');
      _updateStatus('✅ Affectation testée: ${vehicules.length} véhicules trouvés');
    } catch (e) {
      _updateStatus('❌ Erreur affectation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Tests Fonctionnalités',
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[50]!, Colors.purple[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.science, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tests Système',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Vérification des fonctionnalités',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tests disponibles
            const Text(
              '🧪 Tests Disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            
            // Test 1: Génération de données
            _buildTestCard(
              title: 'Générer Données Test',
              description: 'Créer la base de données complète',
              icon: Icons.storage,
              color: Colors.green,
              onPressed: _isLoading ? null : _testGenerateData,
            ),
            
            const SizedBox(height: 12),
            
            // Test 2: Recherche véhicule
            _buildTestCard(
              title: 'Test Recherche Véhicule',
              description: 'Tester la recherche de véhicule tiers',
              icon: Icons.search,
              color: Colors.blue,
              onPressed: _isLoading ? null : _testVehicleSearch,
            ),
            
            const SizedBox(height: 12),
            
            // Test 3: Affectation véhicule
            _buildTestCard(
              title: 'Test Affectation Véhicule',
              description: 'Tester l\'affectation véhicule-conducteur',
              icon: Icons.link,
              color: Colors.orange,
              onPressed: _isLoading ? null : _testVehicleAffectation,
            ),
            
            const SizedBox(height: 24),
            
            // Statut
            if (_statusMessage.isNotEmpty) _buildStatus(),
            
            const SizedBox(height: 24),
            
            // Informations
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ℹ️ Informations',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text('• Tests des fonctionnalités principales', style: TextStyle(fontSize: 12)),
          Text('• Vérification de la base de données', style: TextStyle(fontSize: 12)),
          Text('• Validation des services', style: TextStyle(fontSize: 12)),
          SizedBox(height: 8),
          Text(
            '⚠️ Utilisez ces tests en développement uniquement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
