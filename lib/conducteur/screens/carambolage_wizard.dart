import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicule_model.dart';
import '../../models/accident_session.dart';
import '../../services/accident_session_service.dart';
import 'multi_vehicle_constat_screen.dart';
import 'session_invitation_screen.dart';

/// 🚗 Assistant pour carambolages complexes (+5 véhicules)
class CarambolageWizard extends StatefulWidget {
  const CarambolageWizard({super.key});

  @override
  State<CarambolageWizard> createState() => _CarambolageWizardState();
}

class _CarambolageWizardState extends State<CarambolageWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Configuration dynamique
  int _nombreVehicules = 5;
  final int _maxVehicules = 15; // Limite technique raisonnable
  VehiculeModel? _monVehicule;
  List<VehiculeModel> _mesVehicules = [];
  bool _isLoadingVehicules = true;
  
  // Gestion des rôles dynamiques
  final List<String> _rolesDisponibles = [];
  String? _monRole;

  @override
  void initState() {
    super.initState();
    _chargerMesVehicules();
    _genererRolesDisponibles();
  }

  void _genererRolesDisponibles() {
    _rolesDisponibles.clear();
    for (int i = 0; i < _nombreVehicules; i++) {
      _rolesDisponibles.add(String.fromCharCode(65 + i)); // A, B, C, D, E, F, G, H...
    }
  }

  Future<void> _chargerMesVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // TODO: Charger les véhicules du conducteur depuis Firestore
        _mesVehicules = [
          VehiculeModel(
            id: 'demo_vehicle_001',
            conducteurId: user.uid,
            marque: 'Peugeot',
            modele: '208',
            numeroImmatriculation: '123 TUN 456',
            contratActif: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      }
    } catch (e) {
      print('Erreur chargement véhicules: $e');
    } finally {
      setState(() {
        _isLoadingVehicules = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carambolage Complexe'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildEtapeNombreVehicules(),
                _buildEtapeSelectionVehicule(),
                _buildEtapeConfigurationAvancee(),
              ],
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'Assistant Carambolage Complexe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
          ),
          const SizedBox(height: 8),
          Text(
            'Étape ${_currentStep + 1} sur 3',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeNombreVehicules() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carambolage Complexe',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configurez le nombre exact de véhicules impliqués dans ce carambolage',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Sélecteur de nombre avec slider
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Text(
                        'Nombre de véhicules: $_nombreVehicules',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: _nombreVehicules.toDouble(),
                    min: 5,
                    max: _maxVehicules.toDouble(),
                    divisions: _maxVehicules - 5,
                    label: '$_nombreVehicules véhicules',
                    onChanged: (value) {
                      setState(() {
                        _nombreVehicules = value.round();
                        _genererRolesDisponibles();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Rôles générés: ${_rolesDisponibles.join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Avertissements selon le nombre
          if (_nombreVehicules >= 8)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Carambolage majeur détecté. Assurez-vous que les secours ont été appelés.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else if (_nombreVehicules >= 6)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Carambolage complexe. Le processus peut prendre plus de temps.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // Informations techniques
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Gestion Avancée',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Système extensible jusqu\'à 15 véhicules\n'
                  '• Rôles automatiques (A→O)\n'
                  '• Gestion des délais adaptée\n'
                  '• Priorité haute automatique\n'
                  '• Notifications renforcées',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeSelectionVehicule() {
    if (_isLoadingVehicules) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre Position dans le Carambolage',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez votre véhicule et votre position dans la séquence',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sélection du véhicule
          if (_mesVehicules.isEmpty)
            _buildAucunVehicule()
          else
            ..._mesVehicules.map((vehicule) => _buildVehiculeCard(vehicule)),
          
          const SizedBox(height: 24),
          
          // Sélection du rôle/position
          if (_monVehicule != null) ...[
            const Text(
              'Votre position dans la séquence:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _rolesDisponibles.map((role) {
                final isSelected = _monRole == role;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _monRole = role;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange[600] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? Colors.orange[800]! : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_monRole != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  'Vous serez le véhicule $_monRole dans ce carambolage de $_nombreVehicules véhicules',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehiculeCard(VehiculeModel vehicule) {
    final isSelected = _monVehicule?.id == vehicule.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.orange[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _monVehicule = vehicule;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange[600] : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicule.marque} ${vehicule.modele}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vehicule.numeroImmatriculation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.orange[600],
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAucunVehicule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun véhicule trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous devez d\'abord enregistrer un véhicule.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeConfigurationAvancee() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration Avancée',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Configuration spécialisée pour carambolages complexes avec plus de 6 véhicules.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Priorité haute automatique
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Priorité Haute Automatique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ce carambolage sera traité en priorité haute avec délais réduits.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Assistance spécialisée
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        'Assistance Spécialisée',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Un expert sera automatiquement assigné pour superviser ce carambolage.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _etapePrecedente,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _currentStep < 2 ? _etapeSuivante : _creerCarambolage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.warning),
              label: Text(
                _currentStep < 2 ? 'Suivant' : 'Créer Carambolage',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _etapePrecedente() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _etapeSuivante() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _creerCarambolage() async {
    if (_monRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre rôle de véhicule'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Naviguer vers l'écran de création de session avec les paramètres du carambolage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SessionInvitationScreen(
          typeAccident: 'Carambolage',
          nombreVehicules: _nombreVehicules,
        ),
      ),
    );
  }
}
