import 'package:flutter/material.dart';
import '../../models/accident_session.dart';
import '../../models/accident_participant.dart' as participant_models;
import '../../services/accident_session_service.dart';
import 'vehicle_damage_screen.dart';
import 'accident_sketch_screen.dart';

/// 📝 Écran de formulaire pour un participant (Partie A ou B)
class ParticipantFormScreen extends StatefulWidget {
  final AccidentSession session;
  final participant_models.AccidentParticipant participant;

  const ParticipantFormScreen({
    Key? key,
    required this.session,
    required this.participant,
  }) : super(key: key);

  @override
  State<ParticipantFormScreen> createState() => _ParticipantFormScreenState();
}

class _ParticipantFormScreenState extends State<ParticipantFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers pour les champs de texte
  final _nomConducteurController = TextEditingController();
  final _prenomConducteurController = TextEditingController();
  final _adresseConducteurController = TextEditingController();
  final _telephoneConducteurController = TextEditingController();
  final _emailConducteurController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _categoriePermisController = TextEditingController();
  
  final _marqueVehiculeController = TextEditingController();
  final _typeVehiculeController = TextEditingController();
  final _numeroImmatriculationController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _sensSuiviController = TextEditingController();
  
  final _nomAssuranceController = TextEditingController();
  final _numeroPoliceController = TextEditingController();
  final _numeroCarteVerteController = TextEditingController();
  final _agenceAssuranceController = TextEditingController();
  
  final _nomConducteurHabituelController = TextEditingController();
  final _prenomConducteurHabituelController = TextEditingController();
  final _degatsApparentsController = TextEditingController();
  final _observationsPartieController = TextEditingController();

  // Variables d'état
  DateTime? _dateNaissanceConducteur;
  DateTime? _dateValiditePermis;
  DateTime? _dateValiditeAssurance;
  bool _conducteurHabituel = true;
  bool? _assuranceValide;
  List<int> _circonstancesSelectionnees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _chargerDonneesParticipant();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomConducteurController.dispose();
    _prenomConducteurController.dispose();
    _adresseConducteurController.dispose();
    _telephoneConducteurController.dispose();
    _emailConducteurController.dispose();
    _numeroPermisController.dispose();
    _categoriePermisController.dispose();
    _marqueVehiculeController.dispose();
    _typeVehiculeController.dispose();
    _numeroImmatriculationController.dispose();
    _numeroSerieController.dispose();
    _sensSuiviController.dispose();
    _nomAssuranceController.dispose();
    _numeroPoliceController.dispose();
    _numeroCarteVerteController.dispose();
    _agenceAssuranceController.dispose();
    _nomConducteurHabituelController.dispose();
    _prenomConducteurHabituelController.dispose();
    _degatsApparentsController.dispose();
    _observationsPartieController.dispose();
    super.dispose();
  }

  /// 📋 Charger les données existantes du participant
  void _chargerDonneesParticipant() {
    final p = widget.participant;
    
    _nomConducteurController.text = p.nomConducteur;
    _prenomConducteurController.text = p.prenomConducteur;
    _adresseConducteurController.text = p.adresseConducteur;
    _telephoneConducteurController.text = p.telephoneConducteur;
    _emailConducteurController.text = p.emailConducteur ?? '';
    _numeroPermisController.text = p.numeroPermis ?? '';
    _categoriePermisController.text = p.categoriePermis ?? '';
    
    _marqueVehiculeController.text = p.marqueVehicule;
    _typeVehiculeController.text = p.typeVehicule;
    _numeroImmatriculationController.text = p.numeroImmatriculation;
    _numeroSerieController.text = p.numeroSerie ?? '';
    _sensSuiviController.text = p.sensSuivi ?? '';
    
    _nomAssuranceController.text = p.nomAssurance;
    _numeroPoliceController.text = p.numeroPolice;
    _numeroCarteVerteController.text = p.numeroCarteVerte ?? '';
    _agenceAssuranceController.text = p.agenceAssurance ?? '';
    
    _nomConducteurHabituelController.text = p.nomConducteurHabituel ?? '';
    _prenomConducteurHabituelController.text = p.prenomConducteurHabituel ?? '';
    _degatsApparentsController.text = p.degatsApparents ?? '';
    _observationsPartieController.text = p.observationsPartie ?? '';

    setState(() {
      _dateNaissanceConducteur = p.dateNaissanceConducteur;
      _dateValiditePermis = p.dateValiditePermis;
      _dateValiditeAssurance = p.dateValiditeAssurance;
      _conducteurHabituel = p.conducteurHabituel;
      _assuranceValide = p.assuranceValide;
      _circonstancesSelectionnees = List.from(p.circonstancesSelectionnees);
    });
  }

  /// 💾 Sauvegarder les données
  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updates = {
        'nomConducteur': _nomConducteurController.text.trim(),
        'prenomConducteur': _prenomConducteurController.text.trim(),
        'adresseConducteur': _adresseConducteurController.text.trim(),
        'telephoneConducteur': _telephoneConducteurController.text.trim(),
        'emailConducteur': _emailConducteurController.text.trim(),
        'dateNaissanceConducteur': _dateNaissanceConducteur,
        'numeroPermis': _numeroPermisController.text.trim(),
        'categoriePermis': _categoriePermisController.text.trim(),
        'dateValiditePermis': _dateValiditePermis,
        'marqueVehicule': _marqueVehiculeController.text.trim(),
        'typeVehicule': _typeVehiculeController.text.trim(),
        'numeroImmatriculation': _numeroImmatriculationController.text.trim(),
        'numeroSerie': _numeroSerieController.text.trim(),
        'sensSuivi': _sensSuiviController.text.trim(),
        'nomAssurance': _nomAssuranceController.text.trim(),
        'numeroPolice': _numeroPoliceController.text.trim(),
        'numeroCarteVerte': _numeroCarteVerteController.text.trim(),
        'dateValiditeAssurance': _dateValiditeAssurance,
        'agenceAssurance': _agenceAssuranceController.text.trim(),
        'assuranceValide': _assuranceValide,
        'conducteurHabituel': _conducteurHabituel,
        'nomConducteurHabituel': _nomConducteurHabituelController.text.trim(),
        'prenomConducteurHabituel': _prenomConducteurHabituelController.text.trim(),
        'degatsApparents': _degatsApparentsController.text.trim(),
        'circonstancesSelectionnees': _circonstancesSelectionnees,
        'observationsPartie': _observationsPartieController.text.trim(),
        'statut': participant_models.ParticipantStatut.enSaisie,
      };

      await AccidentSessionService.mettreAJourParticipant(
        widget.participant.id,
        updates,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données sauvegardées avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 📅 Sélectionner une date
  Future<void> _selectionnerDate(String type) async {
    DateTime? initialDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (type) {
      case 'naissance':
        initialDate = _dateNaissanceConducteur;
        firstDate = DateTime(1940);
        lastDate = DateTime.now().subtract(const Duration(days: 365 * 18));
        break;
      case 'permis':
        initialDate = _dateValiditePermis;
        firstDate = DateTime.now();
        lastDate = DateTime.now().add(const Duration(days: 365 * 50));
        break;
      case 'assurance':
        initialDate = _dateValiditeAssurance;
        firstDate = DateTime.now().subtract(const Duration(days: 365));
        lastDate = DateTime.now().add(const Duration(days: 365 * 2));
        break;
      default:
        return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      setState(() {
        switch (type) {
          case 'naissance':
            _dateNaissanceConducteur = date;
            break;
          case 'permis':
            _dateValiditePermis = date;
            break;
          case 'assurance':
            _dateValiditeAssurance = date;
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Partie ${widget.participant.partie} - Formulaire',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.participant.partie == 'A' 
            ? Colors.blue[600] 
            : Colors.green[600],
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Conducteur'),
            Tab(text: 'Véhicule'),
            Tab(text: 'Assurance'),
            Tab(text: 'Détails'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _sauvegarder,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildConducteurTab(),
            _buildVehiculeTab(),
            _buildAssuranceTab(),
            _buildDetailsTab(),
          ],
        ),
      ),
    );
  }

  /// 👤 Onglet Conducteur (Section 6)
  Widget _buildConducteurTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.person,
            'Section 6 - Conducteur',
            'Informations sur le conducteur du véhicule',
          ),
          const SizedBox(height: 16),
          
          // Nom et prénom
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nomConducteurController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _prenomConducteurController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prénom est obligatoire';
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
            controller: _adresseConducteurController,
            decoration: const InputDecoration(
              labelText: 'Adresse complète *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'adresse est obligatoire';
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
                  controller: _telephoneConducteurController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le téléphone est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailConducteurController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date de naissance
          InkWell(
            onTap: () => _selectionnerDate('naissance'),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date de naissance',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              child: Text(
                _dateNaissanceConducteur != null
                    ? '${_dateNaissanceConducteur!.day}/${_dateNaissanceConducteur!.month}/${_dateNaissanceConducteur!.year}'
                    : 'Sélectionner la date',
                style: TextStyle(
                  color: _dateNaissanceConducteur != null 
                      ? Colors.black 
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Permis de conduire
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numeroPermisController,
                  decoration: const InputDecoration(
                    labelText: 'N° Permis de conduire',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _categoriePermisController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date de validité du permis
          InkWell(
            onTap: () => _selectionnerDate('permis'),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Validité du permis',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                _dateValiditePermis != null
                    ? '${_dateValiditePermis!.day}/${_dateValiditePermis!.month}/${_dateValiditePermis!.year}'
                    : 'Sélectionner la date',
                style: TextStyle(
                  color: _dateValiditePermis != null 
                      ? Colors.black 
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Onglet Véhicule (Section 7)
  Widget _buildVehiculeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.directions_car,
            'Section 7 - Véhicule',
            'Informations sur le véhicule impliqué',
          ),
          const SizedBox(height: 16),
          
          // Marque et type
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _marqueVehiculeController,
                  decoration: const InputDecoration(
                    labelText: 'Marque *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.branding_watermark),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La marque est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _typeVehiculeController,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le type est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Numéro d'immatriculation
          TextFormField(
            controller: _numeroImmatriculationController,
            decoration: const InputDecoration(
              labelText: 'N° d\'immatriculation *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le numéro d\'immatriculation est obligatoire';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Numéro de série
          TextFormField(
            controller: _numeroSerieController,
            decoration: const InputDecoration(
              labelText: 'N° de série (châssis)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          
          const SizedBox(height: 16),
          
          // Sens suivi
          TextFormField(
            controller: _sensSuiviController,
            decoration: const InputDecoration(
              labelText: 'Sens suivi (venant de / allant à)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions),
              hintText: 'Ex: Venant de Tunis, allant à Sousse',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  /// 🛡️ Onglet Assurance (Section 8)
  Widget _buildAssuranceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            Icons.security,
            'Section 8 - Société d\'Assurance',
            'Informations sur l\'assurance du véhicule',
          ),
          const SizedBox(height: 16),
          
          // Nom de l'assurance
          TextFormField(
            controller: _nomAssuranceController,
            decoration: const InputDecoration(
              labelText: 'Nom de la société d\'assurance *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom de l\'assurance est obligatoire';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Numéro de police et carte verte
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numeroPoliceController,
                  decoration: const InputDecoration(
                    labelText: 'N° de police *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.policy),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le numéro de police est obligatoire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _numeroCarteVerteController,
                  decoration: const InputDecoration(
                    labelText: 'N° carte verte',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Date de validité de l'assurance
          InkWell(
            onTap: () => _selectionnerDate('assurance'),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Validité de l\'assurance *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.date_range),
              ),
              child: Text(
                _dateValiditeAssurance != null
                    ? '${_dateValiditeAssurance!.day}/${_dateValiditeAssurance!.month}/${_dateValiditeAssurance!.year}'
                    : 'Sélectionner la date',
                style: TextStyle(
                  color: _dateValiditeAssurance != null 
                      ? Colors.black 
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Agence d'assurance
          TextFormField(
            controller: _agenceAssuranceController,
            decoration: const InputDecoration(
              labelText: 'Agence d\'assurance',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          
          const SizedBox(height: 16),
          
          // Assurance valide
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'État de l\'assurance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Valide'),
                          value: true,
                          groupValue: _assuranceValide,
                          onChanged: (value) {
                            setState(() {
                              _assuranceValide = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text('Expirée'),
                          value: false,
                          groupValue: _assuranceValide,
                          onChanged: (value) {
                            setState(() {
                              _assuranceValide = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section 9 - Conducteur habituel
          _buildSectionHeader(
            Icons.person_pin,
            'Section 9 - Conducteur Habituel',
            'Le conducteur est-il le conducteur habituel ?',
          ),
          
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Conducteur habituel du véhicule'),
            subtitle: Text(_conducteurHabituel 
                ? 'Oui, c\'est le conducteur habituel'
                : 'Non, ce n\'est pas le conducteur habituel'),
            value: _conducteurHabituel,
            onChanged: (value) {
              setState(() {
                _conducteurHabituel = value;
              });
            },
          ),
          
          if (!_conducteurHabituel) ...[
            const SizedBox(height: 16),
            const Text(
              'Conducteur habituel:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomConducteurHabituelController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du conducteur habituel',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prenomConducteurHabituelController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom du conducteur habituel',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 📋 Onglet Détails (Sections 10, 11, 12, 14)
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 10 - Point de choc initial
          _buildSectionHeader(
            Icons.touch_app,
            'Section 10 - Point de Choc Initial',
            'Indiquez le point de choc sur votre véhicule',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToVehicleDamage(),
              icon: const Icon(Icons.directions_car),
              label: const Text('Sélectionner les points de choc'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.orange[600]!),
                foregroundColor: Colors.orange[600],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 11 - Dégâts apparents
          _buildSectionHeader(
            Icons.build,
            'Section 11 - Dégâts Apparents',
            'Décrivez les dégâts visibles sur votre véhicule',
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _degatsApparentsController,
            decoration: const InputDecoration(
              labelText: 'Description des dégâts',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              hintText: 'Ex: Pare-choc avant enfoncé, phare cassé...',
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Section 12 - Circonstances
          _buildSectionHeader(
            Icons.list_alt,
            'Section 12 - Circonstances',
            'Cochez les circonstances qui s\'appliquent (cases 11-17)',
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: participant_models.CirconstancesAccident.circonstances.entries.map((entry) {
                  final numero = entry.key;
                  final libelle = entry.value;
                  final isSelected = _circonstancesSelectionnees.contains(numero);
                  
                  return CheckboxListTile(
                    title: Text('$numero. $libelle'),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _circonstancesSelectionnees.add(numero);
                        } else {
                          _circonstancesSelectionnees.remove(numero);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Section 13 - Croquis de l'accident
          _buildSectionHeader(
            Icons.draw,
            'Section 13 - Croquis de l\'Accident',
            'Dessinez un schéma de l\'accident (partagé entre les parties)',
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToSketch(),
              icon: const Icon(Icons.edit),
              label: const Text('Dessiner le croquis de l\'accident'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.blue[600]!),
                foregroundColor: Colors.blue[600],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section 14 - Observations
          _buildSectionHeader(
            Icons.comment,
            'Section 14 - Observations',
            'Vos observations personnelles sur l\'accident',
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _observationsPartieController,
            decoration: const InputDecoration(
              labelText: 'Vos observations',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
              hintText: 'Décrivez ce qui s\'est passé selon vous...',
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🚗 Naviguer vers l'écran de sélection des dégâts
  Future<void> _navigateToVehicleDamage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDamageScreen(
          participantId: widget.participant.id,
          existingDamageData: widget.participant.pointChocData,
        ),
      ),
    );

    if (result != null) {
      // Les données ont été sauvegardées, on peut rafraîchir si nécessaire
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points de choc mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 🎨 Naviguer vers l'écran de croquis
  Future<void> _navigateToSketch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccidentSketchScreen(
          sessionId: widget.session.id,
          existingSketchData: null, // TODO: Adapter selon le modèle existant
        ),
      ),
    );

    if (result != null) {
      // Le croquis a été sauvegardé
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Croquis mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
