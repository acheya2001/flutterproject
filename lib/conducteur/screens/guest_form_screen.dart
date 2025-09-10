import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/collaborative_session_model.dart';
import '../../models/guest_participant_model.dart';
import '../../services/collaborative_session_service.dart';

/// 📋 Formulaire complet pour conducteurs invités non-inscrits
class GuestFormScreen extends StatefulWidget {
  final CollaborativeSession session;

  const GuestFormScreen({
    super.key,
    required this.session,
  });

  @override
  State<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends State<GuestFormScreen>with TickerProviderStateMixin  {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Contrôleurs pour informations personnelles
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _cinController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _codePostalController = TextEditingController();

  // Contrôleurs pour véhicule
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _couleurController = TextEditingController();
  final _anneeController = TextEditingController();

  // Contrôleurs pour assurance
  final _numeroContratController = TextEditingController();
  String? _compagnieSelectionnee;
  String? _agenceSelectionnee;
  List<Map<String, dynamic>> _compagnies = [];
  List<Map<String, dynamic>> _agences = [];

  // Variables d'état
  List<String> _circonstancesSelectionnees = [];
  List<String> _pointsChocSelectionnes = [];
  List<String> _degatsSelectionnes = [];

  final List<String> _etapes = [
    'Informations personnelles',
    'Véhicule',
    'Assurance',
    'Circonstances',
  ];

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _chargerCompagnies();
    _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    // Dispose tous les contrôleurs
    _nomController.dispose();
    _prenomController.dispose();
    _cinController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _codePostalController.dispose();
    _immatriculationController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _couleurController.dispose();
    _anneeController.dispose();
    _numeroContratController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal[600]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildProgressIndicator(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPageView(),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formulaire invité',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Session: ${widget.session.codeSession}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Invité',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_etapes.length, (index) {
              final isActive = index == _currentPage;
              final isCompleted = index < _currentPage;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < _etapes.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isActive 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentPage + 1}/${_etapes.length} - ${_etapes[_currentPage]}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
      children: [
        _buildPageInfosPersonnelles(),
        _buildPageVehicule(),
        _buildPageAssurance(),
        _buildPageCirconstances(),
      ],
    );
  }

  Widget _buildPageInfosPersonnelles() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: Colors.teal[800]),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Nom et prénom
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nom requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prenomController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Prénom requis';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // CIN
              TextFormField(
                controller: _cinController,
                decoration: const InputDecoration(
                  labelText: 'Numéro CIN *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                  hintText: 'Ex: 12345678',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'CIN requis';
                  }
                  if (value.trim().length != 8) {
                    return 'CIN doit contenir 8 chiffres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Téléphone et email
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: '+216 XX XXX XXX',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Téléphone requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email requis';
                        }
                        if (!value.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Adresse
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse complète *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Rue, quartier, ville...',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Adresse requise';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Ville et code postal
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _villeController,
                      decoration: const InputDecoration(
                        labelText: 'Ville *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ville requise';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codePostalController,
                      decoration: const InputDecoration(
                        labelText: 'Code postal',
                        border: OutlineInputBorder(),
                        hintText: '1000',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageVehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
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
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car, color: Colors.blue[800]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Informations du véhicule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Immatriculation
            TextFormField(
              controller: _immatriculationController,
              decoration: const InputDecoration(
                labelText: 'Numéro d\'immatriculation *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
                hintText: 'Ex: 123 TUN 456',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Immatriculation requise';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Marque et modèle
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Marque *',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Peugeot',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Marque requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modeleController,
                    decoration: const InputDecoration(
                      labelText: 'Modèle *',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: 208',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Modèle requis';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Couleur et année
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _couleurController,
                    decoration: const InputDecoration(
                      labelText: 'Couleur *',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: Blanc',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Couleur requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _anneeController,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                      hintText: '2020',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageAssurance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
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
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.security, color: Colors.green[800]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Informations d\'assurance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Compagnie d'assurance
            DropdownButtonFormField<String>(
              value: _compagnieSelectionnee,
              decoration: const InputDecoration(
                labelText: 'Compagnie d\'assurance *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _compagnies.map((compagnie) {
                return DropdownMenuItem<String>(
                  value: compagnie['id'],
                  child: Text(compagnie['nom']),
                );
              }).toList(),
              onChanged: (value) {
                if (mounted) setState(() {
                  _compagnieSelectionnee = value;
                  _agenceSelectionnee = null;
                  _chargerAgences(value!);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Compagnie requise';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Agence
            DropdownButtonFormField<String>(
              value: _agenceSelectionnee,
              decoration: const InputDecoration(
                labelText: 'Agence *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              items: _agences.map((agence) {
                return DropdownMenuItem<String>(
                  value: agence['id'],
                  child: Text(agence['nom']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _agenceSelectionnee = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Agence requise';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Numéro de contrat
            TextFormField(
              controller: _numeroContratController,
              decoration: const InputDecoration(
                labelText: 'Numéro de contrat *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                hintText: 'Ex: ASS123456',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Numéro de contrat requis';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCirconstances() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
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
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.list_alt, color: Colors.orange[800]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Circonstances de l\'accident',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Sélectionnez les circonstances qui s\'appliquent à votre situation :',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            
            // Liste des circonstances
            ..._obtenirCirconstances().map((circonstance) => CheckboxListTile(
              title: Text(
                circonstance,
                style: const TextStyle(fontSize: 14),
              ),
              value: _circonstancesSelectionnees.contains(circonstance),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _circonstancesSelectionnees.add(circonstance);
                  } else {
                    _circonstancesSelectionnees.remove(circonstance);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _precedent,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : (_currentPage == _etapes.length - 1 ? _terminer : _suivant),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_currentPage == _etapes.length - 1 ? Icons.check : Icons.arrow_forward),
              label: Text(_isLoading 
                  ? 'Sauvegarde...' 
                  : (_currentPage == _etapes.length - 1 ? 'Terminer' : 'Suivant')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _precedent() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _suivant() {
    if (_validerPageActuelle()) {
      if (_currentPage < _etapes.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _validerPageActuelle() {
    switch (_currentPage) {
      case 0: // Infos personnelles
        return _formKey.currentState?.validate() ?? false;
      case 1: // Véhicule
        return _immatriculationController.text.isNotEmpty &&
               _marqueController.text.isNotEmpty &&
               _modeleController.text.isNotEmpty &&
               _couleurController.text.isNotEmpty;
      case 2: // Assurance
        return _compagnieSelectionnee != null &&
               _agenceSelectionnee != null &&
               _numeroContratController.text.isNotEmpty;
      case 3: // Circonstances
        return true; // Optionnel
      default:
        return true;
    }
  }

  Future<void> _terminer() async {
    if (!_validerPageActuelle()) return;

    setState(() => _isLoading = true);

    try {
      // Créer les données du participant invité
      final guestData = GuestParticipant(
        sessionId: widget.session.id,
        participantId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        roleVehicule: _obtenirRoleVehicule(),
        infosPersonnelles: PersonalInfo(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          cin: _cinController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          codePostal: _codePostalController.text.trim(),
        ),
        infosVehicule: VehicleInfo(
          immatriculation: _immatriculationController.text.trim(),
          marque: _marqueController.text.trim(),
          modele: _modeleController.text.trim(),
          couleur: _couleurController.text.trim(),
          anneeConstruction: int.tryParse(_anneeController.text),
          pointsChoc: _pointsChocSelectionnes,
          degatsApparents: _degatsSelectionnes,
        ),
        infosAssurance: InsuranceInfo(
          compagnieId: _compagnieSelectionnee ?? '',
          compagnieNom: _obtenirNomCompagnie(_compagnieSelectionnee),
          agenceId: _agenceSelectionnee ?? '',
          agenceNom: _obtenirNomAgence(_agenceSelectionnee),
          numeroContrat: _numeroContratController.text.trim(),
        ),
        circonstances: _circonstancesSelectionnees,
        photosUrls: [],
        dateCreation: DateTime.now(),
        formulaireComplete: true,
      );

      // Sauvegarder les données
      await CollaborativeSessionService.sauvegarderDonneesInvite(guestData);

      // Afficher succès et retourner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Formulaire sauvegardé avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerCompagnies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .get();
      
      setState(() {
        _compagnies = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nom': doc.data()['nom'] ?? 'Compagnie inconnue',
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur chargement compagnies: $e');
    }
  }

  Future<void> _chargerAgences(String compagnieId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('compagnies_assurance')
          .doc(compagnieId)
          .collection('agences')
          .get();
      
      setState(() {
        _agences = snapshot.docs.map((doc) => {
          'id': doc.id,
          'nom': doc.data()['nom'] ?? 'Agence inconnue',
        }).toList();
      });
    } catch (e) {
      print('❌ Erreur chargement agences: $e');
    }
  }

  String _obtenirRoleVehicule() {
    // Déterminer le rôle basé sur le nombre de participants existants
    final roles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    final rolesUtilises = widget.session.participants.map((p) => p.roleVehicule).toSet();
    
    for (final role in roles) {
      if (!rolesUtilises.contains(role)) {
        return role;
      }
    }
    return 'Z'; // Fallback
  }

  String _obtenirNomCompagnie(String? compagnieId) {
    if (compagnieId == null) return '';
    final compagnie = _compagnies.firstWhere(
      (c) => c['id'] == compagnieId,
      orElse: () => {'nom': ''},
    );
    return compagnie['nom'] ?? '';
  }

  String _obtenirNomAgence(String? agenceId) {
    if (agenceId == null) return '';
    final agence = _agences.firstWhere(
      (a) => a['id'] == agenceId,
      orElse: () => {'nom': ''},
    );
    return agence['nom'] ?? '';
  }

  List<String> _obtenirCirconstances() {
    return [
      'Stationnait',
      'Quittait un stationnement',
      'Prenait un stationnement',
      'Sortait d\'un parking',
      'Entrait dans un parking',
      'Circulait',
      'Changeait de file',
      'Doublait',
      'Virait à droite',
      'Virait à gauche',
      'Reculait',
      'Empiétait sur une file réservée',
      'Venait de droite',
      'N\'avait pas observé le signal d\'arrêt',
    ];
  }
}

