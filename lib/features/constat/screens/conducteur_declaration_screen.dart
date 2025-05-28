import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signature/signature.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../constat/models/constat_model.dart' as constat_models;
import '../../constat/models/conducteur_info_model.dart' as conducteur_models;
import '../../constat/models/vehicule_accident_model.dart' as vehicule_models;
import '../../constat/models/assurance_info_model.dart' as assurance_models;
import '../../constat/models/temoin_model.dart' as temoin_models;
import '../../constat/providers/constat_provider.dart';

class ConducteurDeclarationScreen extends StatefulWidget {
  const ConducteurDeclarationScreen({Key? key}) : super(key: key);

  @override
  State<ConducteurDeclarationScreen> createState() => _ConducteurDeclarationScreenState();
}

class _ConducteurDeclarationScreenState extends State<ConducteurDeclarationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Contrôleurs de formulaire
  final _dateController = TextEditingController();
  final _lieuController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _permisController = TextEditingController();
  final _marqueController = TextEditingController();
  final _typeController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _venantDeController = TextEditingController();
  final _allantAController = TextEditingController();
  final _societeAssuranceController = TextEditingController();
  final _numeroContratController = TextEditingController();
  final _agenceController = TextEditingController();
  final _observationsController = TextEditingController();

  // Variables d'état
  DateTime? _dateAccident;
  Position? _position;
  bool _blessesLegers = false;
  bool _degatsMaterielsAutres = false;
  int _nombreVehicules = 2;
  String _conducteurPosition = 'A';
  final List<int> _circonstancesSelectionnees = [];
  final List<String> _degatsApparents = [];
  final List<File> _photosAccident = [];
  final List<temoin_models.TemoinModel> _temoins = [];
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.blue,
    exportBackgroundColor: Colors.white,
  );

  // Photos des documents
  File? _photoPermis;
  File? _photoCarteGrise;
  File? _photoAttestation;

  @override
  void initState() {
    super.initState();
    _obtenirLocalisation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dateController.dispose();
    _lieuController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _permisController.dispose();
    _marqueController.dispose();
    _typeController.dispose();
    _immatriculationController.dispose();
    _venantDeController.dispose();
    _allantAController.dispose();
    _societeAssuranceController.dispose();
    _numeroContratController.dispose();
    _agenceController.dispose();
    _observationsController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _obtenirLocalisation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      _position = await Geolocator.getCurrentPosition();
      if (mounted && _position != null) {
        setState(() {
          _lieuController.text = 'Lat: ${_position!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_position!.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
    }
  }

  Future<void> _selectionnerDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _dateAccident = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _dateController.text = 
              '${_dateAccident!.day}/${_dateAccident!.month}/${_dateAccident!.year} '
              'à ${time.format(context)}';
        });
      }
    }
  }

  Future<void> _prendrePhoto(String type) async {
    final ImagePicker picker = ImagePicker();
    
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null && mounted) {
        setState(() {
          switch (type) {
            case 'permis':
              _photoPermis = File(image.path);
              // TODO: Implémenter OCR pour extraire les informations du permis
              break;
            case 'carte_grise':
              _photoCarteGrise = File(image.path);
              // TODO: Implémenter OCR pour extraire les informations de la carte grise
              break;
            case 'attestation':
              _photoAttestation = File(image.path);
              // TODO: Implémenter OCR pour extraire les informations d'assurance
              break;
            case 'accident':
              _photosAccident.add(File(image.path));
              break;
          }
        });

        // Traitement OCR simulé
        if (type == 'permis') {
          // TODO: Implémenter l'extraction OCR des informations du permis
          _permisController.text = 'Numéro extrait par OCR';
        } else if (type == 'carte_grise') {
          // TODO: Implémenter l'extraction OCR des informations de la carte grise
          _marqueController.text = 'Marque extraite';
          _typeController.text = 'Type extrait';
          _immatriculationController.text = 'Immatriculation extraite';
        } else if (type == 'attestation') {
          // TODO: Implémenter l'extraction OCR des informations d'assurance
          _societeAssuranceController.text = 'Société extraite';
          _numeroContratController.text = 'Numéro extrait';
        }
      }
    }
  }

  void _ajouterTemoin() {
    showDialog(
      context: context,
      builder: (context) => TemoinDialog(
        onTemoinAjoute: (temoin) {
          setState(() {
            _temoins.add(temoin);
          });
        },
      ),
    );
  }

  Future<void> _sauvegarderConstat() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non connecté')),
          );
        }
        return;
      }

      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final constat = constat_models.ConstatModel(
        id: '',
        dateAccident: _dateAccident ?? DateTime.now(),
        lieuAccident: _lieuController.text,
        coordonnees: _position != null 
            ? GeoPoint(_position!.latitude, _position!.longitude) 
            : null,
        adresseAccident: _lieuController.text,
        vehiculeIds: [],
        conducteurIds: [],
        temoinsIds: [],
        photosUrls: [],
        validationStatus: {},
        status: constat_models.ConstatStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: user.id,
        circonstances: {
          'selectionnees': _circonstancesSelectionnees,
          'nombre': _circonstancesSelectionnees.length,
        },
        dommages: {
          'degats': _degatsApparents,
        },
        observations: _observationsController.text.isNotEmpty 
            ? {'texte': _observationsController.text} 
            : null,
      );

      final conducteurInfo = conducteur_models.ConducteurInfoModel(
        nom: _nomController.text,
        prenom: _prenomController.text,
        adresse: _adresseController.text,
        telephone: _telephoneController.text,
        numeroPermis: _permisController.text,
        userId: user.id,
        createdAt: DateTime.now(),
      );

      final vehiculeInfo = vehicule_models.VehiculeAccidentModel(
        marque: _marqueController.text,
        type: _typeController.text,
        numeroImmatriculation: _immatriculationController.text,
        venantDe: _venantDeController.text,
        allantA: _allantAController.text,
        degatsApparents: _degatsApparents,
        conducteurId: '',
        createdAt: DateTime.now(),
      );

      final assuranceInfo = assurance_models.AssuranceInfoModel(
        societeAssurance: _societeAssuranceController.text,
        numeroContrat: _numeroContratController.text,
        agence: _agenceController.text,
        conducteurId: '',
        createdAt: DateTime.now(),
      );

      // Obtenir la signature
      Uint8List? signature;
      if (_signatureController.isNotEmpty) {
        signature = await _signatureController.toPngBytes();
      }

      final constatProvider = Provider.of<ConstatProvider>(context, listen: false);
      
      await constatProvider.sauvegarderConstatComplet(
        constat: constat,
        conducteurInfo: conducteurInfo,
        vehiculeInfo: vehiculeInfo,
        assuranceInfo: assuranceInfo,
        temoins: _temoins,
        photosAccident: _photosAccident,
        photoPermis: _photoPermis,
        photoCarteGrise: _photoCarteGrise,
        photoAttestation: _photoAttestation,
        signature: signature,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Constat sauvegardé avec succès')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Déclarer un accident',
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(7, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentPage 
                          ? Colors.blue 
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          // Titre de l'étape
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _getTitreEtape(_currentPage),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          
          // Contenu des pages
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildEtapeGenerale(),
                _buildEtapeConducteur(),
                _buildEtapeVehicule(),
                _buildEtapeAssurance(),
                _buildEtapeCirconstances(),
                _buildEtapePhotos(),
                _buildEtapeSignature(),
              ],
            ),
          ),
          
          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage == 6 ? _sauvegarderConstat : () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Text(_currentPage == 6 ? 'Sauvegarder' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitreEtape(int page) {
    switch (page) {
      case 0: return 'Informations générales';
      case 1: return 'Informations conducteur';
      case 2: return 'Informations véhicule';
      case 3: return 'Informations assurance';
      case 4: return 'Circonstances';
      case 5: return 'Photos et documents';
      case 6: return 'Signature';
      default: return '';
    }
  }

  Widget _buildEtapeGenerale() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date et heure
          const Text(
            'Date et heure de l\'accident',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Sélectionner la date et l\'heure',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _selectionnerDate,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lieu
          const Text(
            'Lieu de l\'accident',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lieuController,
            decoration: InputDecoration(
              hintText: 'Adresse ou description du lieu',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),

          // Nombre de véhicules
          const Text(
            'Nombre de véhicules impliqués',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [2, 3, 4, 5].map((nombre) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$nombre'),
                    selected: _nombreVehicules == nombre,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _nombreVehicules = nombre;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Position du conducteur
          const Text(
            'Votre position dans le constat',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['A', 'B'].map((position) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('Véhicule $position'),
                    selected: _conducteurPosition == position,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _conducteurPosition = position;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Blessés
          CheckboxListTile(
            title: const Text('Y a-t-il des blessés (même légers) ?'),
            value: _blessesLegers,
            onChanged: (value) {
              setState(() {
                _blessesLegers = value ?? false;
              });
            },
          ),

          // Dégâts matériels
          CheckboxListTile(
            title: const Text('Y a-t-il des dégâts matériels autres qu\'aux véhicules ?'),
            value: _degatsMaterielsAutres,
            onChanged: (value) {
              setState(() {
                _degatsMaterielsAutres = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeConducteur() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vos informations personnelles',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Nom
          TextFormField(
            controller: _nomController,
            decoration: InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Prénom
          TextFormField(
            controller: _prenomController,
            decoration: InputDecoration(
              labelText: 'Prénom',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Adresse
          TextFormField(
            controller: _adresseController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Téléphone
          TextFormField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),

          // Permis de conduire
          const Text(
            'Permis de conduire',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _permisController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de permis',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _prendrePhoto('permis'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ],
          ),
          
          if (_photoPermis != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _photoPermis!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEtapeVehicule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations du véhicule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Marque
          TextFormField(
            controller: _marqueController,
            decoration: InputDecoration(
              labelText: 'Marque',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Type
          TextFormField(
            controller: _typeController,
            decoration: InputDecoration(
              labelText: 'Type/Modèle',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Immatriculation
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _immatriculationController,
                  decoration: InputDecoration(
                    labelText: 'Numéro d\'immatriculation',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _prendrePhoto('carte_grise'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Carte grise'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ],
          ),

          if (_photoCarteGrise != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _photoCarteGrise!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Direction
          const Text(
            'Direction du véhicule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _venantDeController,
            decoration: InputDecoration(
              labelText: 'Venant de',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _allantAController,
            decoration: InputDecoration(
              labelText: 'Allant à',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeAssurance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations d\'assurance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Société d'assurance
          TextFormField(
            controller: _societeAssuranceController,
            decoration: InputDecoration(
              labelText: 'Société d\'assurance',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Numéro de contrat
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _numeroContratController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de contrat',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _prendrePhoto('attestation'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Attestation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ],
          ),

          if (_photoAttestation != null) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _photoAttestation!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Agence
          TextFormField(
            controller: _agenceController,
            decoration: InputDecoration(
              labelText: 'Agence',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeCirconstances() {
    final List<String> circonstances = [
      'en stationnement',
      'quittait un stationnement',
      'prenait un stationnement',
      'sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
      's\'engageait dans un parking, un lieu privé, d\'un chemin de terre',
      'arrêt de circulation',
      'frottement sans changement de file',
      'heurtait à l\'arrière, en roulant dans le même sens et sur une même file',
      'roulait dans le même sens et sur une file différente',
      'changeait de file',
      'doublait',
      'virait à droite',
      'virait à gauche',
      'reculait',
      'empiétait sur la partie de chaussée réservée à la circulation en sens inverse',
      'venait de droite (dans un carrefour)',
      'n\'avait pas observé le signal de priorité',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Circonstances de l\'accident',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cochez toutes les cases correspondant à votre situation :',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          ...circonstances.asMap().entries.map((entry) {
            final index = entry.key;
            final circonstance = entry.value;
            
            return CheckboxListTile(
              title: Text('${index + 1}. $circonstance'),
              value: _circonstancesSelectionnees.contains(index + 1),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _circonstancesSelectionnees.add(index + 1);
                  } else {
                    _circonstancesSelectionnees.remove(index + 1);
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),

          const SizedBox(height: 24),

          // Dégâts apparents
          const Text(
            'Dégâts apparents',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Avant gauche', 'Avant centre', 'Avant droite',
              'Côté gauche', 'Côté droit',
              'Arrière gauche', 'Arrière centre', 'Arrière droite',
              'Toit', 'Pare-brise', 'Vitres latérales',
            ].map((degat) {
              return FilterChip(
                label: Text(degat),
                selected: _degatsApparents.contains(degat),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _degatsApparents.add(degat);
                    } else {
                      _degatsApparents.remove(degat);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapePhotos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos de l\'accident',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prenez des photos de la scène d\'accident, des véhicules et des dégâts',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Bouton pour ajouter des photos
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () => _prendrePhoto('accident'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Grille des photos ajoutées
          if (_photosAccident.isNotEmpty) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photosAccident.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _photosAccident[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _photosAccident.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Témoins
          const Text(
            'Témoins',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_temoins.isEmpty)
            const Text(
              'Aucun témoin ajouté',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...(_temoins.asMap().entries.map((entry) {
              final index = entry.key;
              final temoin = entry.value;
              
              return Card(
                child: ListTile(
                  title: Text(temoin.nom),
                  subtitle: Text(temoin.adresse),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _temoins.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }).toList()),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _ajouterTemoin,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un témoin'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 24),

          // Observations
          const Text(
            'Observations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _observationsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ajoutez vos observations sur l\'accident...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtapeSignature() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signature électronique',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Signez dans le cadre ci-dessous pour valider votre déclaration',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Zone de signature
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Boutons pour la signature
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _signatureController.clear();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_signatureController.isNotEmpty) {
                      final signature = await _signatureController.toPngBytes();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signature enregistrée')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Résumé du constat
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de votre déclaration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildResumeLigne('Date', _dateController.text),
                  _buildResumeLigne('Lieu', _lieuController.text),
                  _buildResumeLigne('Conducteur', '${_prenomController.text} ${_nomController.text}'),
                  _buildResumeLigne('Véhicule', '${_marqueController.text} ${_typeController.text}'),
                  _buildResumeLigne('Immatriculation', _immatriculationController.text),
                  _buildResumeLigne('Assurance', _societeAssuranceController.text),
                  _buildResumeLigne('Circonstances', '${_circonstancesSelectionnees.length} sélectionnées'),
                  _buildResumeLigne('Photos', '${_photosAccident.length} ajoutées'),
                  _buildResumeLigne('Témoins', '${_temoins.length} ajoutés'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeLigne(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              valeur.isEmpty ? 'Non renseigné' : valeur,
              style: TextStyle(
                color: valeur.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog pour ajouter un témoin
class TemoinDialog extends StatefulWidget {
  final Function(temoin_models.TemoinModel) onTemoinAjoute;

  const TemoinDialog({Key? key, required this.onTemoinAjoute}) : super(key: key);

  @override
  State<TemoinDialog> createState() => _TemoinDialogState();
}

class _TemoinDialogState extends State<TemoinDialog> {
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  bool _estPassagerA = false;
  bool _estPassagerB = false;

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telephoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Passager du véhicule A'),
              value: _estPassagerA,
              onChanged: (value) {
                setState(() {
                  _estPassagerA = value ?? false;
                  if (_estPassagerA) _estPassagerB = false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Passager du véhicule B'),
              value: _estPassagerB,
              onChanged: (value) {
                setState(() {
                  _estPassagerB = value ?? false;
                  if (_estPassagerB) _estPassagerA = false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nomController.text.isNotEmpty && _adresseController.text.isNotEmpty) {
              final temoin = temoin_models.TemoinModel(
                nom: _nomController.text,
                adresse: _adresseController.text,
                telephone: _telephoneController.text.isNotEmpty ? _telephoneController.text : null,
                estPassagerA: _estPassagerA,
                estPassagerB: _estPassagerB,
                constatId: '',
                createdAt: DateTime.now(),
              );
              
              widget.onTemoinAjoute(temoin);
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
