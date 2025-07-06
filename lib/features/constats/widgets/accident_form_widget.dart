import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../vehicules/models/vehicule_assure_model.dart';

/// 📝 Widget formulaire pour les informations de l'accident
class AccidentFormWidget extends StatefulWidget {
  final VehiculeAssureModel vehicule;
  final Function(Map<String, dynamic>) onDataChanged;

  const AccidentFormWidget({
    super.key,
    required this.vehicule,
    required this.onDataChanged,
  });

  @override
  State<AccidentFormWidget> createState() => _AccidentFormWidgetState();
}

class _AccidentFormWidgetState extends State<AccidentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _lieuController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Variables
  String _meteo = 'ensoleille';
  String _visibilite = 'bonne';
  String _etatRoute = 'seche';
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _heureController.dispose();
    _lieuController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final now = DateTime.now();
    _dateController.text = '${now.day.toString().padLeft(2, '0')}/'
                          '${now.month.toString().padLeft(2, '0')}/'
                          '${now.year}';
    _heureController.text = '${now.hour.toString().padLeft(2, '0')}:'
                           '${now.minute.toString().padLeft(2, '0')}';

    // Retarder l'appel de _updateData pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildSectionHeader('📅 Date et Heure', 'Quand l\'accident s\'est-il produit ?'),
            
            // Date et heure
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _heureController,
                    decoration: InputDecoration(
                      labelText: 'Heure',
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Lieu
            _buildSectionHeader('📍 Lieu de l\'Accident', 'Où l\'accident s\'est-il produit ?'),
            
            TextFormField(
              controller: _lieuController,
              decoration: InputDecoration(
                labelText: 'Adresse ou description du lieu',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _getCurrentLocation,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
              onChanged: (_) => _updateData(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir le lieu de l\'accident';
                }
                return null;
              },
            ),
            
            if (_currentPosition != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '📍 Position: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                  '${_currentPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Conditions
            _buildSectionHeader('🌤️ Conditions', 'Dans quelles conditions l\'accident s\'est-il produit ?'),
            
            _buildConditionSelector(
              'Météo',
              _meteo,
              ['ensoleille', 'nuageux', 'pluvieux', 'brouillard'],
              ['☀️ Ensoleillé', '☁️ Nuageux', '🌧️ Pluvieux', '🌫️ Brouillard'],
              (value) => setState(() {
                _meteo = value;
                _updateData();
              }),
            ),
            
            const SizedBox(height: 12),
            
            _buildConditionSelector(
              'Visibilité',
              _visibilite,
              ['bonne', 'reduite', 'mauvaise'],
              ['👁️ Bonne', '👁️‍🗨️ Réduite', '🚫 Mauvaise'],
              (value) => setState(() {
                _visibilite = value;
                _updateData();
              }),
            ),
            
            const SizedBox(height: 12),
            
            _buildConditionSelector(
              'État de la route',
              _etatRoute,
              ['seche', 'humide', 'mouillee', 'verglacee'],
              ['🛣️ Sèche', '💧 Humide', '🌊 Mouillée', '🧊 Verglacée'],
              (value) => setState(() {
                _etatRoute = value;
                _updateData();
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Description
            _buildSectionHeader('📝 Description', 'Décrivez ce qui s\'est passé'),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description détaillée de l\'accident',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: (_) => _updateData(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez décrire l\'accident';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Informations du véhicule (lecture seule)
            _buildVehicleInfo(),
          ],
        ),
      ),
    );
  }

  /// 📋 En-tête de section
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 🎛️ Sélecteur de conditions
  Widget _buildConditionSelector(
    String label,
    String value,
    List<String> values,
    List<String> labels,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values.asMap().entries.map((entry) {
            final index = entry.key;
            final val = entry.value;
            final isSelected = value == val;
            
            return ChoiceChip(
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (_) => onChanged(val),
              selectedColor: Colors.purple[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.purple[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🚗 Informations du véhicule
  Widget _buildVehicleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚗 Véhicule Impliqué',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Véhicule', '${widget.vehicule.vehicule.marque} ${widget.vehicule.vehicule.modele}'),
          _buildInfoRow('Immatriculation', widget.vehicule.vehicule.immatriculation),
          _buildInfoRow('Couleur', widget.vehicule.vehicule.couleur),
          _buildInfoRow('Assureur', _getAssureurName(widget.vehicule.assureurId)),
          _buildInfoRow('N° Contrat', widget.vehicule.numeroContrat),
        ],
      ),
    );
  }

  /// 📊 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📅 Sélectionner la date
  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      _dateController.text = '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}/'
                            '${date.year}';
      _updateData();
    }
  }

  /// ⏰ Sélectionner l'heure
  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      _heureController.text = '${time.hour.toString().padLeft(2, '0')}:'
                             '${time.minute.toString().padLeft(2, '0')}';
      _updateData();
    }
  }

  /// 📍 Obtenir la position actuelle
  void _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      
      // TODO: Convertir les coordonnées en adresse
      if (_lieuController.text.isEmpty) {
        _lieuController.text = 'Position GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
      
      _updateData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de géolocalisation: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  /// 🔄 Mettre à jour les données
  void _updateData() {
    final data = {
      'date': _dateController.text,
      'heure': _heureController.text,
      'lieu': _lieuController.text,
      'description': _descriptionController.text,
      'meteo': _meteo,
      'visibilite': _visibilite,
      'etat_route': _etatRoute,
      'position': _currentPosition != null ? {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      } : null,
      'vehicule_id': widget.vehicule.id,
    };
    
    widget.onDataChanged(data);
  }

  /// 🏢 Nom de l'assureur
  String _getAssureurName(String assureurId) {
    switch (assureurId.toUpperCase()) {
      case 'STAR':
        return 'STAR Assurances';
      case 'MAGHREBIA':
        return 'Maghrebia Assurances';
      case 'GAT':
        return 'GAT Assurances';
      default:
        return assureurId;
    }
  }
}
