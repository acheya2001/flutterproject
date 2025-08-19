import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/widgets/modern_card.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../services/insurance_structure_service.dart';

/// 📝 Assistant de création de contrat d'assurance moderne
class CreateContractWizard extends StatefulWidget {
  final String compagnieId;
  final String agenceId;
  final String agentId;

  const CreateContractWizard({
    Key? key,
    required this.compagnieId,
    required this.agenceId,
    required this.agentId,
  }) : super(key: key);

  @override
  State<CreateContractWizard> createState() => _CreateContractWizardState();
}

class _CreateContractWizardState extends State<CreateContractWizard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Données du contrat
  String? _selectedConducteurId;
  String? _selectedVehiculeId;
  String _typeAssurance = 'Tous risques';
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 365));
  double _primeAnnuelle = 0.0;
  double _franchise = 0.0;
  List<String> _garanties = [];
  Map<String, dynamic> _conditions = {};
  
  // Données de recherche
  List<Map<String, dynamic>> _conducteurs = [];
  List<Map<String, dynamic>> _vehicules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageController = PageController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les conducteurs disponibles
      final conducteursSnapshot = await FirebaseFirestore.instance
          .collection('conducteurs')
          .where('status', isEqualTo: 'actif')
          .limit(50)
          .get();

      _conducteurs = conducteursSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVehiculesByConducteur(String conducteurId) async {
    try {
      final vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('conducteurs')
          .doc(conducteurId)
          .collection('vehicles')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _vehicules = vehiculesSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur chargement véhicules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1ConducteurSelection(),
                          _buildStep2VehiculeSelection(),
                          _buildStep3ContractDetails(),
                          _buildStep4Confirmation(),
                        ],
                      ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade600,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau Contrat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Étape ${_currentStep + 1} sur $_totalSteps',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? Colors.blue.shade600
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStepTitle(index),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted || isCurrent
                          ? Colors.blue.shade600
                          : Colors.grey.shade500,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0: return 'Conducteur';
      case 1: return 'Véhicule';
      case 2: return 'Contrat';
      case 3: return 'Confirmation';
      default: return '';
    }
  }

  Widget _buildStep1ConducteurSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionner le conducteur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez le conducteur pour lequel créer le contrat d\'assurance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _conducteurs.isEmpty
                ? _buildEmptyState('Aucun conducteur trouvé')
                : ListView.builder(
                    itemCount: _conducteurs.length,
                    itemBuilder: (context, index) {
                      final conducteur = _conducteurs[index];
                      final isSelected = conducteur['id'] == _selectedConducteurId;
                      
                      return _buildConducteurCard(conducteur, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConducteurCard(Map<String, dynamic> conducteur, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        onTap: () {
          setState(() {
            _selectedConducteurId = conducteur['id'];
          });
          _loadVehiculesByConducteur(conducteur['id']);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [Colors.blue.shade600, Colors.blue.shade800]
                        : [Colors.grey.shade400, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${conducteur['prenom'] ?? ''} ${conducteur['nom'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.blue.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conducteur['email'] ?? 'Email non renseigné',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      conducteur['telephone'] ?? 'Téléphone non renseigné',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2VehiculeSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionner le véhicule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez le véhicule à assurer',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _vehicules.isEmpty
                ? _buildEmptyState('Aucun véhicule trouvé pour ce conducteur')
                : ListView.builder(
                    itemCount: _vehicules.length,
                    itemBuilder: (context, index) {
                      final vehicule = _vehicules[index];
                      final isSelected = vehicule['id'] == _selectedVehiculeId;
                      
                      return _buildVehiculeCard(vehicule, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculeCard(Map<String, dynamic> vehicule, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        onTap: () {
          setState(() {
            _selectedVehiculeId = vehicule['id'];
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue.shade600 : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [Colors.blue.shade600, Colors.blue.shade800]
                        : [Colors.grey.shade400, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicule['brand'] ?? ''} ${vehicule['model'] ?? ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.blue.shade800 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Immatriculation: ${vehicule['plate'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Année: ${vehicule['year'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Précédent'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceedToNextStep() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_currentStep == _totalSteps - 1 ? 'Créer le contrat' : 'Suivant'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0: return _selectedConducteurId != null;
      case 1: return _selectedVehiculeId != null;
      case 2: return _primeAnnuelle > 0;
      case 3: return true;
      default: return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createContract();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createContract() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await InsuranceStructureService.createContrat(
        compagnieId: widget.compagnieId,
        agenceId: widget.agenceId,
        agentId: widget.agentId,
        conducteurId: _selectedConducteurId!,
        vehiculeId: _selectedVehiculeId!,
        typeAssurance: _typeAssurance,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        primeAnnuelle: _primeAnnuelle,
        franchise: _franchise,
        garanties: _garanties,
        conditions: _conditions,
      );

      if (result['success'] == true) {
        Navigator.of(context).pop(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Placeholder pour les étapes 3 et 4
  Widget _buildStep3ContractDetails() {
    return const Center(
      child: Text('Étape 3: Détails du contrat - À implémenter'),
    );
  }

  Widget _buildStep4Confirmation() {
    return const Center(
      child: Text('Étape 4: Confirmation - À implémenter'),
    );
  }
}
