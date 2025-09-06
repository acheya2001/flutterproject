import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/accident_session_complete.dart';
import '../../models/vehicule_model.dart';
import '../../services/accident_session_complete_service.dart';
import 'accident_form_step2_vehicules.dart';

/// 📋 Étape 1 : Informations générales de l'accident (selon constat papier)
class AccidentFormStep1InfosGenerales extends StatefulWidget {
  final AccidentSessionComplete session;
  final Map<String, dynamic>? vehiculeSelectionne;

  const AccidentFormStep1InfosGenerales({
    super.key,
    required this.session,
    this.vehiculeSelectionne,
  });

  @override
  State<AccidentFormStep1InfosGenerales> createState() => _AccidentFormStep1InfosGeneralesState();
}

class _AccidentFormStep1InfosGeneralesState extends State<AccidentFormStep1InfosGenerales> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les champs
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _detailsBlessesController = TextEditingController();
  final _detailsDegatsAutresController = TextEditingController();

  // Variables d'état
  DateTime _dateAccident = DateTime.now();
  TimeOfDay _heureAccident = TimeOfDay.now();
  bool _blesses = false;
  bool _degatsMaterielsAutres = false;
  String _lieuGps = '';
  List<Temoin> _temoins = [];
  bool _isLoadingGPS = false;

  @override
  void initState() {
    super.initState();
    _initialiserFormulaire();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _detailsBlessesController.dispose();
    _detailsDegatsAutresController.dispose();
    super.dispose();
  }

  void _initialiserFormulaire() {
    // Pré-remplir avec les données existantes si disponibles
    final infos = widget.session.infosGenerales;
    
    _dateAccident = infos.dateAccident;
    _dateController.text = '${_dateAccident.day}/${_dateAccident.month}/${_dateAccident.year}';
    
    if (infos.heureAccident.isNotEmpty) {
      _heureController.text = infos.heureAccident;
    } else {
      _heureController.text = '${_heureAccident.hour}:${_heureAccident.minute.toString().padLeft(2, '0')}';
    }
    
    _lieuController.text = infos.lieuAccident;
    _lieuGps = infos.lieuGps;
    _blesses = infos.blesses;
    _detailsBlessesController.text = infos.detailsBlesses;
    _degatsMaterielsAutres = infos.degatsMaterielsAutres;
    _detailsDegatsAutresController.text = infos.detailsDegatsAutres;
    _temoins = List.from(infos.temoins);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Informations générales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _sauvegarder,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),
          
          // Formulaire
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    _buildHeader(),

                    const SizedBox(height: 24),

                    // Informations du véhicule sélectionné (si disponible)
                    if (widget.vehiculeSelectionne != null) ...[
                      _buildVehiculeSelectionneSection(),
                      const SizedBox(height: 24),
                    ],

                    // Date et heure
                    _buildDateHeure(),
                    
                    const SizedBox(height: 24),
                    
                    // Lieu
                    _buildLieu(),
                    
                    const SizedBox(height: 24),
                    
                    // Blessés
                    _buildBlesses(),
                    
                    const SizedBox(height: 24),
                    
                    // Dégâts matériels autres
                    _buildDegatsAutres(),
                    
                    const SizedBox(height: 24),
                    
                    // Témoins
                    _buildTemoins(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          
          // Bouton suivant
          _buildBoutonSuivant(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
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
              const Text(
                'Étape 1 sur 6',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Session: ${widget.session.codeSession}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1 / 6,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Informations générales de l\'accident',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Renseignez les informations de base selon le constat officiel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeure() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date et heure de l\'accident',
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
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: _selectionnerDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _heureController,
                    decoration: const InputDecoration(
                      labelText: 'Heure *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    readOnly: true,
                    onTap: _selectionnerHeure,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Heure requise';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLieu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lieu de l\'accident',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _lieuController,
              decoration: const InputDecoration(
                labelText: 'Adresse ou description du lieu *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                hintText: 'Ex: Avenue Habib Bourguiba, Tunis',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lieu requis';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Affichage des coordonnées GPS si disponibles
            if (_lieuGps.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Position GPS obtenue :',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _lieuGps,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Copier les coordonnées dans le champ adresse
                        _lieuController.text = '${_lieuController.text}\nGPS: $_lieuGps';
                      },
                      icon: Icon(Icons.copy, color: Colors.green[600], size: 18),
                      tooltip: 'Copier dans le champ adresse',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingGPS ? null : _obtenirPositionGPS,
                icon: _isLoadingGPS
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_lieuGps.isEmpty ? Icons.my_location : Icons.check_circle),
                label: Text(
                  _isLoadingGPS
                      ? 'Obtention de la position...'
                      : _lieuGps.isEmpty
                          ? 'Obtenir position GPS'
                          : 'Position GPS obtenue',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _lieuGps.isEmpty
                      ? (_isLoadingGPS ? Colors.orange : Colors.blue)
                      : Colors.green,
                  side: BorderSide(
                    color: _lieuGps.isEmpty
                        ? (_isLoadingGPS ? Colors.orange : Colors.blue)
                        : Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlesses() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blessés (même légers)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _blesses,
                    onChanged: (value) {
                      setState(() {
                        _blesses = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _blesses,
                    onChanged: (value) {
                      setState(() {
                        _blesses = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            if (_blesses) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsBlessesController,
                decoration: const InputDecoration(
                  labelText: 'Détails des blessures',
                  border: OutlineInputBorder(),
                  hintText: 'Décrivez les blessures...',
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDegatsAutres() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dégâts matériels autres que les véhicules',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Murs, feux tricolores, panneaux, etc.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Oui'),
                    value: true,
                    groupValue: _degatsMaterielsAutres,
                    onChanged: (value) {
                      setState(() {
                        _degatsMaterielsAutres = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Non'),
                    value: false,
                    groupValue: _degatsMaterielsAutres,
                    onChanged: (value) {
                      setState(() {
                        _degatsMaterielsAutres = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            if (_degatsMaterielsAutres) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsDegatsAutresController,
                decoration: const InputDecoration(
                  labelText: 'Détails des dégâts',
                  border: OutlineInputBorder(),
                  hintText: 'Décrivez les dégâts matériels...',
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemoins() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Témoins',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _ajouterTemoin,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter un témoin',
                ),
              ],
            ),
            
            if (_temoins.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Aucun témoin ajouté',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              ..._temoins.asMap().entries.map((entry) {
                final index = entry.key;
                final temoin = entry.value;
                return _buildTemoinCard(temoin, index);
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemoinCard(Temoin temoin, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temoin.nom,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (temoin.telephone.isNotEmpty)
                  Text(
                    temoin.telephone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _supprimerTemoin(index),
            icon: const Icon(Icons.delete, color: Colors.red),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonSuivant() {
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
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _continuer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Suivant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
        ),
      ),
    );
  }

  void _selectionnerDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateAccident,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _dateAccident = date;
        _dateController.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }

  void _selectionnerHeure() async {
    final heure = await showTimePicker(
      context: context,
      initialTime: _heureAccident,
    );
    
    if (heure != null) {
      setState(() {
        _heureAccident = heure;
        _heureController.text = '${heure.hour}:${heure.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _obtenirPositionGPS() async {
    print('🛰️ Début obtention GPS...');

    setState(() {
      _isLoadingGPS = true;
    });

    try {
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('🛰️ Service GPS activé: $serviceEnabled');

      if (!serviceEnabled) {
        throw Exception('Le service de localisation est désactivé. Veuillez l\'activer dans les paramètres.');
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🛰️ Permission actuelle: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print('🛰️ Permission après demande: $permission');

        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement. Veuillez l\'autoriser dans les paramètres.');
      }

      print('🛰️ Obtention de la position...');

      // Obtenir la position avec timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final coordonnees = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      print('🛰️ Position obtenue: $coordonnees');

      setState(() {
        _lieuGps = coordonnees;
        _isLoadingGPS = false;
      });

      // Aussi mettre à jour le champ de texte directement
      if (_lieuController.text.isEmpty) {
        _lieuController.text = 'GPS: $coordonnees';
      } else {
        _lieuController.text = '${_lieuController.text}\nGPS: $coordonnees';
      }

      print('🛰️ État mis à jour - _lieuGps: $_lieuGps');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Position GPS obtenue: $coordonnees'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('🛰️ Erreur GPS: $e');

      setState(() {
        _isLoadingGPS = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur GPS: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _ajouterTemoin() {
    // TODO: Ouvrir un dialogue pour ajouter un témoin
    showDialog(
      context: context,
      builder: (context) => _buildDialogueTemoin(),
    );
  }

  Widget _buildDialogueTemoin() {
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final telephoneController = TextEditingController();

    return AlertDialog(
      title: const Text('Ajouter un témoin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nomController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: telephoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nomController.text.trim().isNotEmpty) {
              setState(() {
                _temoins.add(Temoin(
                  nom: nomController.text.trim(),
                  adresse: adresseController.text.trim(),
                  telephone: telephoneController.text.trim(),
                ));
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  void _supprimerTemoin(int index) {
    setState(() {
      _temoins.removeAt(index);
    });
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final infosGenerales = InfosGeneralesAccident(
        dateAccident: _dateAccident,
        heureAccident: _heureController.text,
        lieuAccident: _lieuController.text.trim(),
        lieuGps: _lieuGps,
        blesses: _blesses,
        detailsBlesses: _detailsBlessesController.text.trim(),
        degatsMaterielsAutres: _degatsMaterielsAutres,
        detailsDegatsAutres: _detailsDegatsAutresController.text.trim(),
        temoins: _temoins,
      );

      await AccidentSessionCompleteService.mettreAJourInfosGenerales(
        widget.session.id,
        infosGenerales,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations sauvegardées'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _continuer() async {
    if (!_formKey.currentState!.validate()) return;

    // Sauvegarder d'abord
    await _sauvegarder();

    if (mounted) {
      // Naviguer vers l'étape suivante
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentFormStep2Vehicules(
            session: widget.session,
            vehiculeSelectionne: widget.vehiculeSelectionne,
          ),
        ),
      );
    }
  }

  Widget _buildVehiculeSelectionneSection() {
    if (widget.vehiculeSelectionne == null) return const SizedBox.shrink();

    final vehicule = widget.vehiculeSelectionne!['vehicule'] as VehiculeModel;
    final estProprietaire = widget.vehiculeSelectionne!['estProprietaire'] as bool;
    final conducteur = widget.vehiculeSelectionne!['conducteur'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.green[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Véhicule sélectionné',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Informations du véhicule
          _buildInfoRowVehicule('Véhicule', '${vehicule.marque} ${vehicule.modele}'),
          _buildInfoRowVehicule('Immatriculation', vehicule.numeroImmatriculation),
          _buildInfoRowVehicule('Assurance', vehicule.compagnieAssurance ?? 'N/A'),
          if (vehicule.agenceNom != null)
            _buildInfoRowVehicule('Agence', vehicule.agenceNom!),
          _buildInfoRowVehicule('N° Police', vehicule.numeroPolice ?? 'N/A'),

          const SizedBox(height: 12),

          // Informations du conducteur
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conducteur',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                if (estProprietaire) ...[
                  const Text(
                    '✓ Propriétaire du véhicule',
                    style: TextStyle(fontSize: 14),
                  ),
                ] else ...[
                  Text('Nom: ${conducteur['nom']} ${conducteur['prenom']}'),
                  Text('Adresse: ${conducteur['adresse']}'),
                  Text(
                    'Permis: ${conducteur['aPermis'] ? '✓ Oui' : '✗ Non'}',
                    style: TextStyle(
                      color: conducteur['aPermis'] ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowVehicule(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
