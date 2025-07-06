import 'package:flutter/material.dart';
import '../services/insurance_company_service.dart';
import '../models/compagnie_model.dart';

/// 🏢 Écran d'initialisation du système d'assurance
class InsuranceSystemInitScreen extends StatefulWidget {
  const InsuranceSystemInitScreen({super.key});

  @override
  State<InsuranceSystemInitScreen> createState() => _InsuranceSystemInitScreenState();
}

class _InsuranceSystemInitScreenState extends State<InsuranceSystemInitScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _initResults;
  List<CompagnieModel> _companies = [];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '🏢 Système d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
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
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏗️ Initialisation du Système',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Compagnies → Agences → Agents → Clients',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.rocket_launch,
                    label: 'Initialiser Système',
                    color: Colors.green,
                    onPressed: _isLoading ? null : _initializeSystem,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.refresh,
                    label: 'Recharger',
                    color: Colors.orange,
                    onPressed: _isLoading ? null : _loadCompanies,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Résultats d'initialisation
            if (_initResults != null) _buildInitResults(),

            // Liste des compagnies
            if (_companies.isNotEmpty) _buildCompaniesList(),

            // Loading
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Initialisation en cours...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildInitResults() {
    final compagniesCreated = _initResults!['compagnies_created'] as int;
    final agencesCreated = _initResults!['agences_created'] as int;
    final errors = _initResults!['errors'] as List<String>;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Résultats d\'Initialisation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Statistiques
          Row(
            children: [
              _buildStatChip('Compagnies', compagniesCreated.toString(), Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip('Agences', agencesCreated.toString(), Colors.green),
              const SizedBox(width: 8),
              _buildStatChip('Erreurs', errors.length.toString(), Colors.red),
            ],
          ),
          
          if (errors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Erreurs:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '❌ $error',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCompaniesList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏢 Compagnies d\'Assurance (${_companies.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._companies.map((company) => _buildCompanyCard(company)),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(CompagnieModel company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company.numeroAgrement,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${company.typesAssurance.length} types d\'assurance',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: company.active ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              company.active ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: company.active ? Colors.green[700] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _initializeSystem() async {
    setState(() {
      _isLoading = true;
      _initResults = null;
    });

    try {
      final results = await InsuranceCompanyService.initializeInsuranceSystem();
      setState(() {
        _initResults = results;
      });
      
      // Recharger les compagnies
      await _loadCompanies();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Système d\'assurance initialisé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final companies = await InsuranceCompanyService.getAllCompanies();
      setState(() {
        _companies = companies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
