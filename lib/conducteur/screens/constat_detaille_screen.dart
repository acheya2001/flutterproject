import 'package:flutter/material.dart';
import '../../models/accident_session.dart';
import '../../models/vehicule_model.dart';

/// 📋 Formulaire de constat détaillé basé sur le constat papier officiel
class ConstatDetailleScreen extends StatefulWidget {
  final AccidentSession session;
  final String roleVehicule; // A, B, C, etc.
  final VehiculeModel? vehicule;
  final bool estProprietaire;
  final Map<String, String>? infoConducteur;
  final bool peutModifier;

  const ConstatDetailleScreen({
    super.key,
    required this.session,
    required this.roleVehicule,
    this.vehicule,
    this.estProprietaire = true,
    this.infoConducteur,
    this.peutModifier = true,
  });

  @override
  State<ConstatDetailleScreen> createState() => _ConstatDetailleScreenState();
}

class _ConstatDetailleScreenState extends State<ConstatDetailleScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Données du formulaire
  final Map<String, dynamic> _donneesConstat = {};

  // Contrôleurs pour les champs
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _categoriePermisController = TextEditingController();
  final _validitePermisController = TextEditingController();

  // Véhicule
  final _marqueController = TextEditingController();
  final _typeController = TextEditingController();
  final _numeroImmatriculationController = TextEditingController();
  final _paysImmatriculationController = TextEditingController();

  // Assurance
  final _compagnieAssuranceController = TextEditingController();
  final _numeroPoliceController = TextEditingController();
  final _numeroCarteVerteController = TextEditingController();
  final _validiteAssuranceController = TextEditingController();
  final _agenceController = TextEditingController();

  // Circonstances
  final Map<String, bool> _circonstances = {};
  final _observationsController = TextEditingController();

  // Dégâts
  final _degatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialiserFormulaire();
  }

  void _initialiserFormulaire() {
    // Pré-remplir avec les données du véhicule si disponible
    if (widget.vehicule != null) {
      _marqueController.text = widget.vehicule!.marque;
      _typeController.text = widget.vehicule!.modele;
      _numeroImmatriculationController.text = widget.vehicule!.numeroImmatriculation;
      _paysImmatriculationController.text = 'Tunisie';
      
      if (widget.vehicule!.compagnieAssurance != null) {
        _compagnieAssuranceController.text = widget.vehicule!.compagnieAssurance!;
      }
      if (widget.vehicule!.numeroPolice != null) {
        _numeroPoliceController.text = widget.vehicule!.numeroPolice!;
      }
    }

    // Pré-remplir avec les infos du conducteur si différent du propriétaire
    if (!widget.estProprietaire && widget.infoConducteur != null) {
      _nomController.text = widget.infoConducteur!['nom'] ?? '';
      _numeroPermisController.text = widget.infoConducteur!['numeroPermis'] ?? '';
      _telephoneController.text = widget.infoConducteur!['telephone'] ?? '';
    }

    // Initialiser les circonstances
    _initialiserCirconstances();
  }

  void _initialiserCirconstances() {
    final circonstancesStandard = [
      'stationnait',
      'quittait un stationnement',
      'prenait un stationnement',
      'sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
      'entrait dans un parking, un lieu privé, un chemin de terre',
      'entrait dans une file de circulation',
      'roulait',
      'roulait dans le même sens et sur la même file',
      'changeait de file',
      'doublait',
      'virait à droite',
      'virait à gauche',
      'reculait',
      'empiétait sur une file réservée à la circulation en sens inverse',
      'venait de droite (dans un carrefour)',
      'n\'avait pas observé un signal de priorité ou un feu de signalisation',
    ];

    for (String circonstance in circonstancesStandard) {
      _circonstances[circonstance] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Constat Véhicule ${widget.roleVehicule}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _sauvegarder,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de progression
          _buildProgressIndicator(),
          
          // Contenu des pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildPage1Conducteur(),
                _buildPage2Vehicule(),
                _buildPage3Assurance(),
                _buildPage4Circonstances(),
                _buildPage5Degats(),
                _buildPage6Observations(),
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
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.roleVehicule,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitreSection(_currentPage),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Section ${_currentPage + 1} sur $_totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${((_currentPage + 1) / _totalPages * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  String _getTitreSection(int page) {
    switch (page) {
      case 0: return 'Conducteur';
      case 1: return 'Véhicule';
      case 2: return 'Assurance';
      case 3: return 'Circonstances';
      case 4: return 'Dégâts';
      case 5: return 'Observations';
      default: return 'Section ${page + 1}';
    }
  }

  Widget _buildPage1Conducteur() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Conducteur du Véhicule ${widget.roleVehicule}',
              Icons.person,
              Colors.blue,
            ),
            
            const SizedBox(height: 24),
            
            // Statut conducteur/propriétaire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.estProprietaire ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.estProprietaire 
                            ? 'Propriétaire et Conducteur'
                            : 'Conducteur (non propriétaire)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.estProprietaire ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Informations personnelles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations Personnelles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(
                              labelText: 'Nom *',
                              border: OutlineInputBorder(),
                            ),
                            enabled: widget.peutModifier,
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
                            enabled: widget.peutModifier,
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
                    
                    TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse complète *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      maxLines: 2,
                      enabled: widget.peutModifier,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Adresse requise';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _telephoneController,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            enabled: widget.peutModifier,
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
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: widget.peutModifier,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Permis de conduire
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permis de Conduire',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _numeroPermisController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de permis *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      enabled: widget.peutModifier,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Numéro de permis requis';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoriePermisController,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              border: OutlineInputBorder(),
                              hintText: 'B, A, C...',
                            ),
                            enabled: widget.peutModifier,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _validitePermisController,
                            decoration: const InputDecoration(
                              labelText: 'Validité jusqu\'au',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            enabled: widget.peutModifier,
                            onTap: widget.peutModifier ? _selectionnerDateValiditePermis : null,
                            readOnly: true,
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String titre, IconData icon, Color couleur) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titre,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pagePrecedente,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _currentPage < _totalPages - 1 ? _pageSuivante : _finaliser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_currentPage < _totalPages - 1 ? Icons.arrow_forward : Icons.check),
              label: Text(
                _currentPage < _totalPages - 1 ? 'Suivant' : 'Finaliser',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes de navigation et actions
  void _pagePrecedente() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pageSuivante() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectionnerDateValiditePermis() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    
    if (date != null) {
      _validitePermisController.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  void _sauvegarder() {
    // TODO: Sauvegarder les données
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données sauvegardées'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _finaliser() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // TODO: Finaliser le constat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Constat finalisé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }

  // Placeholder pour les autres pages
  Widget _buildPage2Vehicule() {
    return const Center(child: Text('Page Véhicule - À implémenter'));
  }

  Widget _buildPage3Assurance() {
    return const Center(child: Text('Page Assurance - À implémenter'));
  }

  Widget _buildPage4Circonstances() {
    return const Center(child: Text('Page Circonstances - À implémenter'));
  }

  Widget _buildPage5Degats() {
    return const Center(child: Text('Page Dégâts - À implémenter'));
  }

  Widget _buildPage6Observations() {
    return const Center(child: Text('Page Observations - À implémenter'));
  }
}
