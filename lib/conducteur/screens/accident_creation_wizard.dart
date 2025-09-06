import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vehicule_model.dart';
import '../../models/accident_session.dart';
import '../../services/accident_session_service.dart';
import '../../services/vehicule_service.dart';
import 'multi_vehicle_constat_screen.dart';

/// 🎯 Assistant de création d'accident multi-véhicules
class AccidentCreationWizard extends StatefulWidget {
  final int? nombreVehiculesInitial;
  final VehiculeModel? vehiculeSelectionne;
  final bool? estProprietaire;
  final Map<String, String>? infoConducteur;

  const AccidentCreationWizard({
    super.key,
    this.nombreVehiculesInitial,
    this.vehiculeSelectionne,
    this.estProprietaire,
    this.infoConducteur,
  });

  @override
  State<AccidentCreationWizard> createState() => _AccidentCreationWizardState();
}

class _AccidentCreationWizardState extends State<AccidentCreationWizard> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Étape 1: Nombre de véhicules
  late int _nombreVehicules;
  
  // Étape 2: Sélection du véhicule du créateur
  VehiculeModel? _vehiculeSelectionne;
  List<VehiculeModel> _mesVehicules = [];
  bool _isLoadingVehicules = true;
  bool _isLoading = false;
  
  // Étape 3: Configuration des rôles
  final Map<String, String> _rolesLabels = {
    'A': 'Véhicule A (Moi)',
    'B': 'Véhicule B',
    'C': 'Véhicule C',
    'D': 'Véhicule D',
    'E': 'Véhicule E',
  };

  @override
  void initState() {
    super.initState();
    _nombreVehicules = widget.nombreVehiculesInitial ?? 2;
    _vehiculeSelectionne = widget.vehiculeSelectionne;

    // Si le véhicule est déjà sélectionné et le nombre défini, commencer à l'étape 2
    if (widget.vehiculeSelectionne != null && widget.nombreVehiculesInitial != null) {
      _currentStep = 1; // Commencer à l'étape de sélection véhicule (déjà fait)
    }

    _chargerMesVehicules();
  }

  Future<void> _chargerMesVehicules() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Charger les véhicules du conducteur depuis Firestore
        _mesVehicules = await VehiculeService.obtenirVehiculesUtilisateur(user.uid);
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
        title: const Text('Créer un Constat'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildEtape1NombreVehicules(),
                _buildEtape2SelectionVehicule(),
                _buildEtape3ConfigurationRoles(),
              ],
            ),
          ),
          
          // Navigation
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
              Icon(Icons.car_crash, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text(
                'Assistant de Création de Constat',
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!),
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

  Widget _buildEtape1NombreVehicules() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Combien de véhicules sont impliqués ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez le nombre total de véhicules dans cet accident',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Options de nombre de véhicules
          ...List.generate(4, (index) {
            final nombre = index + 2; // 2, 3, 4, 5 véhicules
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: _nombreVehicules == nombre ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _nombreVehicules == nombre 
                        ? Colors.red[600]! 
                        : Colors.grey[300]!,
                    width: _nombreVehicules == nombre ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _nombreVehicules = nombre;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _nombreVehicules == nombre 
                                ? Colors.red[600] 
                                : Colors.grey[400],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              '$nombre',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$nombre véhicules',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                nombre == 2 
                                    ? 'Accident simple entre 2 véhicules'
                                    : 'Collision multiple avec $nombre véhicules',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_nombreVehicules == nombre)
                          Icon(
                            Icons.check_circle,
                            color: Colors.red[600],
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          
          const Spacer(),
          
          // Information importante
          Container(
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
                const Expanded(
                  child: Text(
                    'Vous allez créer une session collaborative. Chaque conducteur remplira sa propre partie du constat.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape2SelectionVehicule() {
    if (_isLoadingVehicules) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionnez votre véhicule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez le véhicule que vous conduisiez lors de l\'accident',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          if (_mesVehicules.isEmpty)
            _buildAucunVehicule()
          else
            ..._mesVehicules.map((vehicule) => _buildVehiculeCard(vehicule)),
        ],
      ),
    );
  }

  Widget _buildVehiculeCard(VehiculeModel vehicule) {
    final isSelected = _vehiculeSelectionne?.id == vehicule.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.red[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _vehiculeSelectionne = vehicule;
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
                    color: isSelected ? Colors.red[600] : Colors.grey[400],
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
                      if (vehicule.contratActif)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Contrat actif',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.red[600],
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
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun véhicule assuré disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vous devez avoir un véhicule avec une assurance active pour déclarer un sinistre.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Souscrivez d\'abord une assurance pour votre véhicule, puis revenez déclarer votre sinistre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/conducteur-dashboard',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtape3ConfigurationRoles() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration des rôles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Répartition des $_nombreVehicules véhicules dans le constat',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Liste des rôles
          ...List.generate(_nombreVehicules, (index) {
            final role = String.fromCharCode(65 + index); // A, B, C, D, E
            final isMonVehicule = index == 0; // Le créateur est toujours le véhicule A

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isMonVehicule ? 4 : 1,
                color: isMonVehicule ? Colors.red[50] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isMonVehicule ? Colors.red[600]! : Colors.grey[300]!,
                    width: isMonVehicule ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isMonVehicule ? Colors.red[600] : Colors.grey[400],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Center(
                          child: Text(
                            role,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMonVehicule
                                  ? 'Véhicule $role (Vous)'
                                  : 'Véhicule $role',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isMonVehicule
                                  ? '${_vehiculeSelectionne?.marque} ${_vehiculeSelectionne?.modele}'
                                  : 'Sera rempli par invitation',
                              style: TextStyle(
                                fontSize: 14,
                                color: isMonVehicule ? Colors.red[700] : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMonVehicule)
                        Icon(
                          Icons.person,
                          color: Colors.red[600],
                          size: 24,
                        )
                      else
                        Icon(
                          Icons.mail_outline,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Information sur le processus
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
                      'Processus de collaboration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Vous remplirez votre partie (Véhicule A)\n'
                  '2. Vous inviterez les autres conducteurs\n'
                  '3. Chaque conducteur remplira sa propre partie\n'
                  '4. Personne ne peut modifier la partie des autres\n'
                  '5. Le constat sera finalisé quand tous auront signé',
                  style: TextStyle(fontSize: 14),
                ),
              ],
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
              onPressed: _isLoading ? null : (_currentStep < 2 ? _etapeSuivante : _creerSession),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.check),
              label: Text(
                _isLoading
                  ? 'Création...'
                  : (_currentStep < 2 ? 'Suivant' : 'Créer Session'),
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

  Future<void> _creerSession() async {
    // Validation
    if (_vehiculeSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre véhicule'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Créer la session d'accident
      final session = await AccidentSessionService.creerNouvelleSession(
        lieu: 'Lieu à définir', // TODO: Récupérer depuis un formulaire
        lieuGps: null,
        dateAccident: DateTime.now(),
        heureAccident: TimeOfDay.now(),
        nombreVehicules: _nombreVehicules,
      );

      // Naviguer vers l'écran multi-véhicules
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MultiVehicleConstatScreen(
              sessionId: session.id,
              monRole: 'A', // Le créateur est toujours véhicule A
              monVehicule: _vehiculeSelectionne!,
              nombreVehicules: _nombreVehicules,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
